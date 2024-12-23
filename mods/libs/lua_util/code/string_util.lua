-- copied from https://github.com/DanWaLes/Warzone/tree/master/mods/libs/lua_util

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

function split(str, separator)
	-- https://stackoverflow.com/questions/1426954/split-string-in-lua#answer-7615129

	if not separator then
		separator = '%s';
	end

	local t = {};

	for str in string.gmatch(str, '([^'.. separator ..']+)') do
		table.insert(t, str);
	end

	return t;
end

function escapePattern(str)
	-- https://www.lua.org/pil/20.2.html
	-- https://www.lua.org/pil/20.3.html
	-- https://stackoverflow.com/questions/9790688/escaping-strings-for-gsub

	return string.gsub(str, '([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1');
end

function toCaseInsensitivePattern(str)
	-- https://www.lua.org/pil/20.4.html

    return string.gsub(str, "%a", function(c)
		return string.format("[%s%s]", string.lower(c), string.upper(c));
	end);
end
