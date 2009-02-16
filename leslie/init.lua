require "leslie.utils"
require "leslie.class-leslie0"
require "leslie.parser"

module("leslie", package.seeall)

version = "0.1a-pre"

class("Template", _M)

---
function Template:initialize(template)

  local lexer = leslie.parser.Lexer()
  local parser = leslie.parser.Parser(lexer:tokenize(template))

  self.nodelist = parser:parse()
end

---
function Template:render(context)

  if context.instanceof == nil or
     not context:instanceof(Context) then
    context = Context(context)
  end

  return self.nodelist:render(context)
end

class("Context", _M)

---
function Context:initialize(t)
  self.context = t or {}
end

---
function Context:evaluate(filter)

  local start_char = filter:sub(1, 1)

  if start_char == "\"" or start_char == "'" then
    do return filter:sub(2, -2) end
  end

  local new = {}
  local filter = leslie.utils.split(filter, leslie.parser.VARIABLE_ATTRIBUTE_SEPARATOR)
  local last = table.remove(filter)

  if #filter > 0 then
    for i, var in ipairs(filter) do
      if i == 1 then
        if self.context[var] == nil then
          do return nil end
        end
        new = self.context[var]
      else
        if new[var] == nil then
          do return nil end
        end
        new = new[var]
      end
    end
  else
    do return self.context[last] end
  end

  return new[last]
end

---
function Context:filter(filter)

  local new = {}
  local filter = leslie.utils.split(filter, leslie.parser.VARIABLE_ATTRIBUTE_SEPARATOR)
  local last = table.remove(filter)

  if #filter > 0 then
    for i, var in ipairs(filter) do
      if i == 1 then
        if self.context[var] == nil then
          do return Context() end
        end
        new = self.context[var]
      else
        if new[var] == nil then
          do return Context() end
        end
        new = new[var]
      end
    end
  else
    do return Context(self.context[last]) end
  end

  return Context(new[last])
end

---
function loader(filename)
  local file, err = io.open(filename, "r")

  if err then
    error("Template " .. filename .. " not found")
  end

  return Template(file:read("*a"))
end
