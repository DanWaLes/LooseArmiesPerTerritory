require '_util';
require '_settings';

function Server_StartGame(game)
	local teams = {};
	local cardPieces = {
		noTeam = {},
		teammed = {}
	};
	local playerGD = Mod.PlayerGameData;
	local teamsNeedingShownReceivedCardsMsg = {};

	function addStartingPieces(player)
		local team = player.Team == -1 and player.ID or player.Team;
		local cards = {'Reconnaissance+'};

		for _, cardName in pairs(cards) do
			if getSetting('Enable' .. cardName) then
				local startingPieces = getSetting(cardName .. 'StartPieces');
				local piecesInCard = getSetting(cardName .. 'PiecesInCard');

				if player.Team == -1 then
					cardPieces.noTeam[team].currentPieces[cardName] = startingPieces;

					if cardPieces.noTeam[team].currentPieces[cardName] >= piecesInCard then
						playerGD[team].shownReceivedCardsMsg = false;
					end
				else
					if not cardPieces.teammed[team].currentPieces[cardName] then
						cardPieces.teammed[team].currentPieces[cardName] = 0;
					end

					cardPieces.teammed[team].currentPieces[cardName] = cardPieces.teammed[team].currentPieces[cardName] + startingPieces;

					if cardPieces.teammed[team].currentPieces[cardName] >= piecesInCard then
						table.insert(teamsNeedingShownReceivedCardsMsg, team);
					end
				end
			end
		end
	end

	for playerId, player in pairs(game.ServerGame.Game.Players) do
		if player.Team == -1 then
			cardPieces.noTeam[playerId] = {
				currentPieces = {}
			};
		else
			if not teams[player.Team] then
				teams[player.Team] = {
					members = {}
				};

				cardPieces[player.Team] = {
					currentPieces = {}
				};
			end

			table.insert(teams[player.Team].members, playerId);
		end

		playerGD[playerId] = {
			prefShowReceivedCardsMsg = true,
			shownReceivedCardsMsg = true
		};

		addStartingPieces(player);
	end

	for _, teamId in pairs(teamsNeedingShownReceivedCardsMsg) do
		for _, playerId in pairs(teams[teamId].members) do
			playerGD[playerId].shownReceivedCardsMsg = false;
		end
	end

	Mod.PublicGameData = {
		teams = teams,
		cardPieces = cardPieces
	};

	Mod.PlayerGameData = playerGD;
end