require "leslie.class-leslie0"

module("leslie.filters", package.seeall)

---
function add(var, arg)
  return tonumber(var) + tonumber(arg)
end

local register_filter = leslie.parser.register_filter

-- register builtin filter
register_filter("add")