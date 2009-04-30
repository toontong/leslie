require "lpeg"

module("leslie.utils", package.seeall)

local smart_split_re

do
  local quot, space = lpeg.S("\""), lpeg.S(" ")
  local tag = (1 - space) - quot
  local str = quot * (tag * (space * tag)^0)^0 * quot

  local elem = lpeg.C((tag + str)^1)
  smart_split_re = lpeg.Ct((elem * (space * elem)^0)^1)
end

---
function split(str, sep, trim)
  str = str .. sep
  local bits = {str:match((str:gsub("[^"..sep.."]*"..sep, "([^"..sep.."]*)"..sep)))}
  
  if trim then
    for i=1, #bits do
      bits[i] = strip(bits[i])
    end
  end
  
  for i=1, #bits do
    if bits[i]:sub(1, 1) == "\"" then
      bits[i] = bits[i]:sub(2, -2)
    end
  end
  
  return bits
end

---
function strip(s)
  return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

---
function smart_split(s)

  if s == "" or s == nil then
    do return {} end
  end

  return lpeg.match(smart_split_re, s)
end
