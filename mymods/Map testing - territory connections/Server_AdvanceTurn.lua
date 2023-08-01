require '_util';

local doneSkippingTurn1 = false;

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder)
	if game.ServerGame.Game.TurnNumber == 1 and not doneSkippingTurn1 then
		-- if turn 1 prevent all orders - get income from bonuses and no income mod turn before
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
		return;
	end
end

function Server_AdvanceTurn_End(game, addNewOrder)
	if game.ServerGame.Game.TurnNumber == 1 then
		doneSkippingTurn1 = true;
	end

	makeDeployments(game, addNewOrder);
	makeAttacks(game, addNewOrder);

	local playerOwnedTerrs = setupNextTurn(game, addNewOrder);
	setIncomesToZero(game, addNewOrder, playerOwnedTerrs);
end

function makeDeployments(game, addNewOrder)
	local mods = {};
	local n = Mod.PublicGameData.terrNo - Mod.PublicGameData.numPlayers;

	while n < Mod.PublicGameData.terrNo do
		local terrId = Mod.PublicGameData.terrNames[n].id;
		local terr = game.Map.Territories[terrId];
		local mod = WL.TerritoryModification.Create(terrId);

		mod.SetArmiesTo = #terr.ConnectedTo + numConnectionsWithPlayers(game, n);
		table.insert(mods, mod);
		n = n + 1;
	end

	addNewOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, 'Made deployments', nil, mods));
end

function numConnectionsWithPlayers(game, attackFromN)
	local terrId = Mod.PublicGameData.terrNames[attackFromN].id;
	local terr = game.Map.Territories[terrId];
	local numPlayerConnections = 0;

	for connectedTerrId in pairs(terr.ConnectedTo) do
		local n = Mod.PublicGameData.terrNo - Mod.PublicGameData.numPlayers;

		while n < Mod.PublicGameData.terrNo do
			if connectedTerrId == Mod.PublicGameData.terrNames[n].id then
				numPlayerConnections = numPlayerConnections + 1;
			end

			n = n + 1;
		end
	end

	return numPlayerConnections;
end

function makeAttacks(game, addNewOrder)
	local n = Mod.PublicGameData.terrNo - Mod.PublicGameData.numPlayers;

	while n < Mod.PublicGameData.terrNo do
		local terrId = Mod.PublicGameData.terrNames[n].id;
		local terr = game.Map.Territories[terrId];
		local terr2 = game.ServerGame.LatestTurnStanding.Territories[terrId];

		for connectedTerrId in pairs(terr.ConnectedTo) do
			addNewOrder(WL.GameOrderAttackTransfer.Create(terr2.OwnerPlayerID, terrId, connectedTerrId, WL.AttackTransferEnum.AttackTransfer, false, WL.Armies.Create(1), false));
		end

		n = n + 1;
	end
end

function setupNextTurn(game, addNewOrder)
	local mods = {};

	-- only update the territories that need changing
	-- LatestTurnStanding doesnt know territories have been attacked
	local n = Mod.PublicGameData.terrNo - Mod.PublicGameData.numPlayers;

	while n < Mod.PublicGameData.terrNo do
		local terrId = Mod.PublicGameData.terrNames[n].id;
		local terr = game.Map.Territories[terrId];
		local mod = WL.TerritoryModification.Create(terrId);

		mod.SetArmiesTo = 0;
		mod.SetOwnerOpt = WL.PlayerID.Neutral;
		table.insert(mods, mod);

		for connectedTerrId in pairs(terr.ConnectedTo) do
			local mod = WL.TerritoryModification.Create(connectedTerrId);

			mod.SetArmiesTo = 0;
			mod.SetOwnerOpt = WL.PlayerID.Neutral;
			table.insert(mods, mod);
		end

		n = n + 1;
	end

	local playerOwnedTerrs = {};
	local terrNo = Mod.PublicGameData.terrNo;
	local numTerrs = #Mod.PublicGameData.terrNames;

	for playerId in pairs(game.ServerGame.Game.PlayingPlayers) do
		if terrNo > numTerrs then
			break;
		end

		local terrId = Mod.PublicGameData.terrNames[terrNo].id;
		local mod = WL.TerritoryModification.Create(terrId);

		mod.SetOwnerOpt = playerId;
		table.insert(mods, mod);
		playerOwnedTerrs[playerId] = terrId;
		terrNo = terrNo + 1;
	end

	local pgd = Mod.PublicGameData;
	pgd.terrNo = terrNo;
	Mod.PublicGameData = pgd;

	addNewOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, 'Setup next turn', nil, mods));
	return playerOwnedTerrs;
end

function setIncomesToZero(game, addNewOrder, playerOwnedTerrs)
	-- LatestTurnStanding doesnt update in time after terr mods are made
	local incomeMods = {};

	for playerId, terrId in pairs(playerOwnedTerrs) do
		local income = 0;
		local terr = game.Map.Territories[terrId];

		-- small chance 1 territory could be in a lot of bonuses of itself
		for _, bonusId in pairs(terr.PartOfBonuses) do
			local bonus = game.Map.Bonuses[bonusId];

			if #bonus.Territories == 1 then
				if game.Settings.OverriddenBonuses[bonusId] then
					income = income + game.Settings.OverriddenBonuses[bonusId];
				else
					income = income + bonus.Amount;
				end
			end
		end

		if income > 0 then
			table.insert(incomeMods, WL.IncomeMod.Create(playerId, -income, 'Removed all income'));
		end
	end

	addNewOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral, 'Removed everyones income', nil, nil, nil, incomeMods));
end