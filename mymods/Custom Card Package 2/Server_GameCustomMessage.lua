require '_util';

function Server_GameCustomMessage(game, playerId, payload, setReturn)
	if type(payload) ~= 'table' then
		return;
	end
	print('init Server_GameCustomMessage');

	for storageType in pairs(payload) do
		local stored = Mod[storageType];

		for key, value in pairs(payload[storageType]) do
			if storageType == 'PlayerGameData' then
				stored[playerId][key] = value;
			else
				stored[key] = value;
			end
		end

		Mod[storageType] = stored;
	end

	setReturn({
		PlayerGameData = Mod.PlayerGameData[playerId],
		PublicGameData = Mod.PublicGameData
	});
end