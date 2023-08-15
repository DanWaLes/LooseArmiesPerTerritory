require 'version';
require '_settings';
require '_util';

local playersWithSuccessfulAttacks = {};

function Server_AdvanceTurn_Start(game)
	for playerId in pairs(game.ServerGame.Game.PlayingPlayers) do
		playersWithSuccessfulAttacks[playerId] = false;
	end
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	local wz = {
		game = game,
		order = order,
		result = result,
		addNewOrder = addNewOrder,
		skipThisOrder = skipThisOrder
	};

	processGameOrderCustom(wz);
	processGameOrderAttackTransfer(wz);
end

function Server_AdvanceTurn_End(game, addNewOrder)
	local earnedPieces = {};

	for _, cardName in pairs(Mod.PublicGameData.cardNames) do
		local enabled = getSetting('Enable' .. cardName);
		local numPieces = getSetting(cardName .. 'MinPiecesPerTurn');
		local needsAttack = getSetting(cardName .. 'NeedsSuccessfulAttackToEarnPiece');

		if enabled and numPieces and numPieces ~= 0 then
			if needsAttack then
				for playerId, hadSuccessfulAttack in pairs(playersWithSuccessfulAttacks) do
					local player = game.ServerGame.Game.Players[playerId];

					if player.State == WL.GamePlayerState.Playing and hadSuccessfulAttack then
						if not earnedPieces[playerId] then
							earnedPieces[playerId] = {};
						end

						earnedPieces[playerId][cardName] = numPieces;
					end
				end
			else
				for playerId in pairs(game.ServerGame.Game.PlayingPlayers) do
					if not earnedPieces[playerId] then
						earnedPieces[playerId] = {};
					end

					earnedPieces[playerId][cardName] = numPieces;
				end
			end
		end
	end

	for playerId in pairs(earnedPieces) do
		local msgPrefix = game.ServerGame.Game.PlayingPlayers[playerId].DisplayName(nil, false) .. ' received ';
		local payloadPrefix = 'CCP2_addCardPieces_' .. playerId .. '_<';

		for cardName, numPieces in pairs(earnedPieces[playerId]) do
			local msg = msgPrefix .. numPieces .. ' piece' .. (numPieces > 1 and 's' or '') .. ' of a ' .. cardName .. ' Card';
			local payload = payloadPrefix .. cardName .. '=[' .. numPieces .. ']>';
			local order = WL.GameOrderCustom.Create(playerId, msg, payload);

			addNewOrder(order);
		end
	end
end

function processGameOrderCustom(wz)
	if not (wz.order.proxyType == 'GameOrderCustom' and startsWith(wz.order.Payload, 'CCP2_')) then
		return;
	end

	if wz.game.Settings.SinglePlayer and not canRunMod() then
		return;
	end

	parseGameOrderCustom(wz);
end

function parseGameOrderCustom(wz)
	-- 'CCP2_addCardPieces_1000_<Reconnaissance+=[1],Reconnaissance+=[-1]>'
	-- 'CCP2_useCard_1000_<Reconnaissance+=[100],Reconnaissance+=[]>'

	local commands = {
		addCardPieces = addCardPieces,
		useCard = useCard
	};

	local _, _, command, playerId, cards = string.find(wz.order.Payload, '^CCP2_([^_]+)_(%d+)_<([^>]+)>$');
	playerId = round(tonumber(playerId));

	if playerId and wz.game.ServerGame.Game.PlayingPlayers[playerId] and command and cards and commands[command] then
		local player = wz.game.ServerGame.Game.PlayingPlayers[playerId];
		local commaSplit = split(cards, ',');

		for _, str2 in pairs(commaSplit) do
			local _, _, cardName, param = string.find(str2, '^([^=]+)=%[([^%]]*)%]$');

			if cardName and param and getSetting('Enable' .. cardName) then
				-- custom orders arent always displayed
				-- safe to skip valid ones and create unstoppable events that say what happened
				wz.skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);

				commands[command](wz, player, cardName, param);
			end
		end
	end
end

function addCardPieces(wz, player, cardName, param)
	local numPieces = round(tonumber(param));

	if numPieces == 0 then
		return;
	end

	local publicGD = Mod.PublicGameData;
	local teamType = player.Team == -1 and 'noTeam' or 'teammed';
	local teamId = player.Team == -1 and player.ID or player.Team;
	local result = publicGD.cardPieces[teamType][teamId].currentPieces[cardName] + numPieces;
	local resulting = result > -1 and result or 0;

	publicGD.cardPieces[teamType][teamId].currentPieces[cardName] = resulting;
	Mod.PublicGameData = publicGD;

	local playerGD = Mod.PlayerGameData;
	local members = player.Team == -1 and {teamId} or publicGD.teams[teamId].members;
	local shownReceivedCardsMsg = resulting < getSetting(cardName .. 'PiecesInCard');

	for _, playerId in pairs(members) do
		playerGD[playerId].shownReceivedCardsMsg = shownReceivedCardsMsg;
	end

	Mod.PlayerGameData = playerGD;

	local msgPrefix = player.DisplayName(nil, false) .. ' received ';
	local msg = msgPrefix .. numPieces .. ' piece' .. (numPieces ~= 1 and 's' or '') .. ' of a ' .. cardName .. ' Card';
	wz.addNewOrder(WL.GameOrderEvent.Create(player.ID, msg, {}));
end

function useCard(wz, player, cardName, param)
	local use = {
		['Reconnaissance+'] = useCardReconnaissancePlus
	};

	-- need to check if enough pieces to play card
	local piecesInCard = getSetting(cardName .. 'PiecesInCard');
	local publicGD = Mod.PublicGameData;
	local teamType = player.Team == -1 and 'noTeam' or 'teammed';
	local teamId = player.Team == -1 and player.ID or player.Team;

	if Mod.PublicGameData.cardPieces[teamType][teamId].currentPieces[cardName] < piecesInCard then
		return;
	end

	local success = use[cardName](wz, player, cardName, param);
	if not success then
		return;
	end

	-- reduce number of current pieces
	local result = publicGD.cardPieces[teamType][teamId].currentPieces[cardName] - piecesInCard;
	publicGD.cardPieces[teamType][teamId].currentPieces[cardName] = result > -1 and result or 0;
	Mod.PublicGameData = publicGD;
end

function useCardReconnaissancePlus(wz, player, cardName, param)
	if not wz.game.Settings.Cards or not wz.game.Settings.Cards[WL.CardID.Reconnaissance] then
		return;
	end

	local startTerrId = tonumber(param);
	local startTerr = wz.game.Map.Territories[startTerrId];

	if not startTerr then
		return;
	end
	
	wz.addNewOrder(WL.GameOrderEvent.Create(player.ID, 'Played a ' .. cardName .. ' Card on ' .. startTerr.Name, {}));

	local range = getSetting(cardName .. 'Range');
	local doneTerrs = {};

	function main(i, terrIds)
		if i == range then
			return;
		end

		local nextTerrs = {};
		for _, terrId in pairs(terrIds) do
			if not doneTerrs[terrId] then
				local reconCard = WL.NoParameterCardInstance.Create(WL.CardID.Reconnaissance);
				local order = WL.GameOrderPlayCardReconnaissance.Create(reconCard.ID, player.ID, terrId);

				wz.addNewOrder(order);

				if i + 1 < range then
					local terr = wz.game.Map.Territories[terrId];

					for connectedTo in pairs(terr.ConnectedTo) do
						table.insert(nextTerrs, connectedTo);
					end
				end

				doneTerrs[terrId] = true;
			end
		end

		main(i + 1, nextTerrs);
	end

	main(0, {startTerrId});

	return true;
end

function processGameOrderAttackTransfer(wz)
	if wz.order.proxyType ~= 'GameOrderAttackTransfer' then
		return;
	end

	if wz.order.PlayerID == WL.PlayerID.Neutral then
		return;
	end

	if playersWithSuccessfulAttacks[wz.order.PlayerID] then
		return;
	end

	if wz.result.IsAttack and wz.result.IsSuccessful then
		playersWithSuccessfulAttacks[wz.order.PlayerID] = true;
	end
end