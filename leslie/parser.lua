require "leslie.class-leslie0"
require "leslie.lexer"

module("leslie.parser", package.seeall)

VARIABLE_ATTRIBUTE_SEPARATOR = '.'

class("Node", _M)

---
function Node:render()
  return ""
end

require "leslie.tags"

class("TextNode", _M) (Node)

---
function TextNode:initialize(str)
  self.str = str
end

---
function TextNode:render(context)
  return self.str or ""
end

class("VariableNode", _M) (Node)

---
function VariableNode:initialize(filter_expression)
  self.filter_expression = filter_expression
end

---
function VariableNode:render(context)
  return context:evaluate(self.filter_expression) or ""
end

class("NodeList", _M)

---
function NodeList:initialize()
  self.nodes = {}
end

---
function NodeList:extend(node)
  table.insert(self.nodes, node)
end

---
function NodeList:render(context)

  local bits = {}

  for i, node in ipairs(self.nodes) do
    data = node:render(context)
    table.insert(bits, data)
  end

  return table.concat(bits)
end

class("Parser", _M)

---
function Parser:initialize(tokens)
  self.tokens = tokens
  self.tags = {
    ["if"] = leslie.tags.do_if,
    ["for"] = leslie.tags.do_for,
    ["comment"] = leslie.tags.do_comment,
    ["firstof"] = leslie.tags.do_firstof,
    ["ifequal"] = leslie.tags.do_ifequal,
    ["ifnotequal"] = leslie.tags.do_ifequal,
    ["with"] = leslie.tags.do_with,
  }
end

---
function Parser:parse(parse_until)

  local nodelist = NodeList()

  if parse_until == nil then
    parse_until = {}
  end

  while self.tokens[1] do
    token = self:next_token()
    if token.token_type == TOKEN_TEXT then
      local node = TextNode(token.contents)
      nodelist:extend(node)
    elseif token.token_type == TOKEN_VAR then
      local node = VariableNode(token.contents)
      nodelist:extend(node)
    elseif token.token_type == TOKEN_BLOCK then
      local command = token:split_contents()[1]
      for _, until_command in ipairs(parse_until) do
        if command == until_command then
          self:prepend_token(token)
          do return nodelist end
        end
      end

      local compile_func = self.tags[command]
      assert(compile_func, "tag '" .. command .. "' unknown.")
      local node = compile_func(self, token)
      nodelist:extend(node)
    end
  end

  return nodelist
end

---
function Parser:next_token()
  return table.remove(self.tokens, 1)
end

---
function Parser:prepend_token(token)
  table.insert(self.tokens, 1, token)
end

---
function Parser:delete_first_token()
  table.remove(self.tokens, 1)
end
