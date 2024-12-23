function round(n, dp)
	if not n then
		print('n is nil');
		return;
	end

	-- http://lua-users.org/wiki/SimpleRound
	local multi = 10 ^ (dp or 0);

	return math.floor((n * multi + 0.5)) / multi;
end

function numKeys(tbl)
	local n = 0;

	for k, v in pairs(tbl) do
		n = n + 1;
	end

	return n;
end

function startsWith(str, sub)
	return string.sub(str, 1, string.len(sub)) == sub;
end

function split(str, sepperator)
	-- https://stackoverflow.com/questions/1426954/split-string-in-lua#answer-7615129
	if not sepperator then
		sepperator = '%s';
	end

	local t = {};
	for str in string.gmatch(str, '([^'.. sepperator ..']+)') do
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

function toCaseInsensativePattern(str)
	-- https://www.lua.org/pil/20.4.html

    return string.gsub(str, "%a", function(c)
		return string.format("[%s%s]", string.lower(c), string.upper(c));
	end);
end
