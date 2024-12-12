-- modified from https://github.com/DanWaLes/Warzone/tree/master/mods/libs/AutoSettingsFiles

require('settings');
require('ui');

function getSettings()
	return {
		addSetting('CreateDistributionWastelandsAfterPicks', 'Create distribution wastelands after picks', 'bool', false, {
			help = function(parent)
				Label(parent).SetText('Takes affect on all distribution wastelands');
				Label(parent).SetText('Only does a difference in manual distribution games');
			end
		}),
		addSetting('UseMaxTerrs', 'Prevent wastelands from reducing max territory limit', 'bool', true, {
			help = function(parent)
				Label(parent).SetText('If there is no territory limit then all players will have at least one spawn');
				Label(parent).SetText('Applies to normal wastelands and extra distribution wastelands');
			end
		}),
		addSetting('OverlapsEnabled', 'Enable wasteland overlaps', 'bool', false, {
			help = function(parent)
				Label(parent).SetText('Wastelands occupy as many neutral or pickable territories as possible before replacing an existing wasteland');
				Label(parent).SetText('The "Overlap mode" will decide how overlaps are dealt with');
			end,
			subsettings = {
				addSetting('OverlapMode', 'Overlap mode', 'int', 1, {
					minValue = 1,
					maxValue = 4,
					help = function(parent)
						Label(parent).SetText('In the event of wastelands randomly getting placed on top of each other, what should happen?');
						Label(parent).SetText('1 = randomly choose which gets used');
						Label(parent).SetText('2 = newest overrides');
						Label(parent).SetText('3 = use smallest wasteland');
						Label(parent).SetText('4 = use largest wasteland');
					end
				}),
				addSetting('TreatAllNeutralsAsWastelands', 'Treat all neutrals as wastelands', 'bool', true, {
					help = function(parent)
						Label(parent).SetText('If enabled the runtime wastelands will follow the wasteland overlap mode for all neutral territories');
						Label(parent).SetText('If disabled the new wasteland will always replace the territory');
						Label(parent).SetText('If "Max overlaps per turn" is 1 then no new wastelands will be created');
						Label(parent).SetText('Applies to runtime wastelands only');
					end
				}),
				addSetting('MaxOverlaps', 'Max overlaps per turn', 'int', 0, {
					minValue = 0,
					maxValue = 3,
					help = function(parent)
						Label(parent).SetText('This setting is only here for performance reasons');
						Label(parent).SetText('Fewer overlaps is faster; 0 = unlimited');
						Label(parent).SetText('Existing wastelands are decided first then lowest to highest wasteland group number are created');
					end
				})
			}
		})
		addSettingTemplate('extraWasteland', 'Add new wasteland group', function(n)
			return {
				label = 'Enable extra wastelands' .. tostring(n),
				settings = {
					addSetting('W' .. tostring(n) .. 'Num', 'Number of wastelands', 'int', 5, {
						minValue = 1,
						maxValue = 15,
						absoluteMax = 4000-- 4000 is max territories a map can have
					}),
					addSetting('W' .. tostring(n) .. 'Size', 'Wasteland size', 'int', 5, {
						minValue = 0,
						maxValue = 100,
						absoluteMax = 100000-- highest allowed in custom scenario
					}),
					addSetting('W' .. tostring(n) .. 'Rand', 'Random +/- amount', 'int', 0, {
						minValue = 0,
						maxValue = 15,
						absoluteMax = 100000,
						help = function(parent)
							Label(parent).SetText('Wastelands will have their size increased or lowered by up to this much');
						end
					}),
					addSetting('W' .. tostring(n) .. 'Type', 'Wasteland type', 'int', 1, {
						minValue = 1,
						maxValue = 3,
						help = function(parent)
							Label(parent).SetText('1 = distribution wasteland');
							Label(parent).SetText('2 = runtime wasteland');
							Label(parent).SetText('3 = both');
						end
					})
				}
			}
		end)
	};
end