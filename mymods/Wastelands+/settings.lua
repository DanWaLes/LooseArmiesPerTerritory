function getSettings()
	function extraWastelandSetting(n)
		local defaultVal = false;

		if n == 1 then
			defaultVal = true;
		end

		return {
			name = 'EnabledW' .. n,
			inputType = 'bool',
			defaultValue =  defaultVal,
			label = 'Enable extra wastelands ' .. n,
			subsettings = {
				{
					name = 'W' .. n .. 'Num',
					inputType = 'int',
					defaultValue = 5,
					minValue = 1,
					maxValue = 15,
					absoluteMax = false,
					label = 'Number of wastelands'
				},
				{
					name = 'W' .. n .. 'Size',
					inputType = 'int',
					defaultValue = 5,
					minValue = 0,
					maxValue = 1000,
					absoluteMax = 100000,
					label = 'Wasteland size'
				},
				{
					name = 'W' .. n .. 'Rand',
					inputType = 'int',
					defaultValue = 0,
					minValue = 0,
					maxValue = 15,
					absoluteMax = false,
					label = 'Random +/- amount',
					help = function(parent)
						UI.CreateLabel(parent).SetText('Wastelands will have their size increased or lowered by up to this much');
					end
				},
				{
					name = 'W' .. n .. 'Type',
					inputType = 'int',
					defaultValue = 1,
					minValue = 1,
					maxValue = 3,
					label = 'Wasteland type',
					help = function(parent)
						UI.CreateLabel(parent).SetText('1 = normal wasteland');
						UI.CreateLabel(parent).SetText('2 = runtime wasteland');
						UI.CreateLabel(parent).SetText('3 = both');
					end
				}
			}
		}
	end

	return {
		{
			name = 'UseMaxTerrs',
			inputType = 'bool',
			defaultValue = true,
			label = 'Prevent wastelands from reducing max territory limit',
			help = function(parent)
				UI.CreateLabel(parent).SetText('If there is no territory limit then all players will have at least one spawn');
				UI.CreateLabel(parent).SetText('Only takes affect on normal wastelands');
			end
		},
		{
			name = 'OverlapMode',
			inputType = 'int',
			defaultValue = 1,
			minValue = 1,
			maxValue = 5,
			label = 'Wasteland overlap mode',
			help = function(parent)
				UI.CreateLabel(parent).SetText('In the event of wastelands randomly getting placed on top of each other, what should happen?');
				UI.CreateLabel(parent).SetText('1 = randomly choose which gets used');
				UI.CreateLabel(parent).SetText('2 = oldest preserved');
				UI.CreateLabel(parent).SetText('3 = newest overrides');
				UI.CreateLabel(parent).SetText('4 = use smallest wasteland');
				UI.CreateLabel(parent).SetText('5 = use largest wasteland');
			end
		},
		{
			name = 'TreatAllNeutralsAsWastelands',
			inputType = 'bool',
			defaultValue = true,
			label = 'Treat all neutrals as wastelands',
			help = function(parent)
				UI.CreateLabel(parent).SetText('If enabled the runtime wastelands will follow the wasteland overlap mode for all neutral territories');
				UI.CreateLabel(parent).SetText('If disabled the new wasteland will always replace the territory');
				UI.CreateLabel(parent).SetText('Applies to runtime wastelands only');
			end
		},
		extraWastelandSetting(1),
		extraWastelandSetting(2),
		extraWastelandSetting(3),
		extraWastelandSetting(4)
	};
end