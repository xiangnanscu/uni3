local function str2number(s)
  local year, month, day, hour, min, sec = s:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
  return os.time { day = day, month = month, year = year, hour = hour, min = min, sec = sec }
end

local function numnber2str(n)
  return os.date("%Y-%m-%d %H:%M:%S", n)
end

return {
  str2number = str2number,
  numnber2str = numnber2str,
}
