require "leslie.class-leslie0"

module("leslie.tags", package.seeall)

class("IfNode", _M) (leslie.parser.Node)

---
function IfNode:initialize(nodelist_true, nodelist_false, cond_expression)
  self.nodelist_true = nodelist_true
  self.nodelist_false = nodelist_false
  self.cond_expression = cond_expression
end

---
function IfNode:render(context)
  local cond_value = context:evaluate(self.cond_expression)

  if cond_value and cond_value ~= "" and cond_value ~= 0 then
    do return self.nodelist_true:render(context) end
  end

  return self.nodelist_false:render(context)
end

class("ForNode", _M) (leslie.parser.Node)

---
function ForNode:initialize(nodelist, nodelist_empty, filter_expression, unpack_list)
  self.nodelist = nodelist
  self.nodelist_empty = nodelist_empty
  self.filter_expression = filter_expression
  self.unpack_list = unpack_list
end

---
function ForNode:render(context)
  local bits = {}
  local for_context = context:filter(self.filter_expression)

  if #for_context.context == 0 then
    do return self.nodelist_empty:render(context) end
  end

  local unpack_mode = (#self.unpack_list > 1) and type(for_context.context[1]) == "table"
  local forloop_vars = {}
  local loops = #for_context.context

  if context.context.forloop ~= nil then
    forloop_vars.parentloop = context.context.forloop
  end
  -- todo: loop Context generator
  for i, loop_context in ipairs(for_context.context) do
    forloop_vars.counter = i
    forloop_vars.counter0 = i -1
    forloop_vars.revcounter = loops - i + 1
    forloop_vars.revcounter0 = loops - i
    forloop_vars.first = (i == 1)
    forloop_vars.last = (i == loops)

    if unpack_mode then
      local copy = loop_context
      loop_context = leslie.Context({forloop = forloop_vars})
      for i, alias in ipairs(self.unpack_list) do
        loop_context.context[alias] = copy[i]
      end
    else
      loop_context = leslie.Context(
        {[self.unpack_list[1]] = loop_context, forloop = forloop_vars}
      )
    end
    table.insert(bits, self.nodelist:render(loop_context))
  end

  return table.concat(bits)
end

class("CommentNode", _M) (leslie.parser.Node)

class("FirstOfNode", _M) (leslie.parser.Node)

---
function FirstOfNode:initialize(vars)
  self.vars = vars
end

---
function FirstOfNode:render(context)
  local value

  while self.vars[1] do
    value = context:evaluate(self.vars[1])
    if value and value ~= "" and value ~= 0 then
      do return tostring(value) end
    end
    table.remove(self.vars, 1)
  end

  return ""
end

class("IfEqualNode", _M) (leslie.parser.Node)

---
function IfEqualNode:initialize(nodelist_true, nodelist_false, var, var2, mode)
  self.nodelist_true = nodelist_true
  self.nodelist_false = nodelist_false
  self.var = var
  self.var2 = var2
  self.mode = mode
end

---
function IfEqualNode:render(context)
  local var_value = context:evaluate(self.var)
  local var2_value = context:evaluate(self.var2)

  local equal = var_value == var2_value or (
          var_value == false and var2_value == 0 or
          var_value == 0 and var2_value == false
        )

  if self.mode == 0 and equal or
    self.mode == 1 and not equal then
    do return self.nodelist_true:render(context) end
  end

  return self.nodelist_false:render(context)
end

class("WithNode", _M) (leslie.parser.Node)

---
function WithNode:initialize(nodelist, filter_expression, alias)
  self.nodelist = nodelist
  self.filter_expression = filter_expression
  self.alias = alias
end

---
function WithNode:render(context)
  local new_context = context:filter(self.filter_expression)
  local with_context = leslie.Context({[self.alias] = new_context.context})

  return self.nodelist:render(with_context)
end

---
function do_if(parser, token)
  local nodelist_true = parser:parse({"else", "endif"})
  local nodelist_false

  if parser:next_token():split_contents()[1] == "else" then
    nodelist_false = parser:parse({"endif"})
    parser:delete_first_token()
  else
    nodelist_false = leslie.parser.NodeList({})
  end

  local args = token:split_contents()

  if #args > 2 then
    error("if command: to many arguments")
  end

  return IfNode(nodelist_true, nodelist_false, args[2])
end

---
function do_for(parser, token)

  local args = token:split_contents()
  local argc = #args
  local unpack_list = {}

  if args[argc - 1] ~= "in" then
    error("for command: invalid arguments")
  end

  if argc > 4 then
    local arg
    for i=2, argc - 2 do
      arg = args[i]
      if arg:sub(-1) == "," then
        arg = arg:sub(1, -2)
      end
      table.insert(unpack_list, arg)
    end
  else
    unpack_list[1] = args[2]
  end

  local nodelist = parser:parse({"empty", "endfor"})
  local nodelist_empty = leslie.parser.NodeList()

  if parser:next_token():split_contents()[1] == "empty" then
    nodelist_empty = parser:parse({"endfor"})
    parser:delete_first_token()
  end

  return ForNode(nodelist, nodelist_empty, args[argc], unpack_list)
end

---
function do_comment(parser, token)
  parser:skip_past("endcomment")

  return CommentNode()
end

---
function do_firstof(parser, token)
  local args = token:split_contents()

  table.remove(args, 1)

  return FirstOfNode(args)
end

---
function do_ifequal(parser, token)
  local nodelist_true = parser:parse({"else", "endifequal", "endifnotequal"})
  local nodelist_false

  if parser:next_token():split_contents()[1] == "else" then
    nodelist_false = parser:parse({"endifequal", "endifnotequal"})
    parser:delete_first_token()
  else
    nodelist_false = leslie.parser.NodeList({})
  end

  local args = token:split_contents()
  local mode = 0

  if args[1] == "ifnotequal" then
    mode = 1
  end

  if #args > 3 then
    error("ifequal command: to many arguments")
  end

  return IfEqualNode(nodelist_true, nodelist_false, args[2], args[3], mode)
end

---
function do_with(parser, token)
  local args = token:split_contents()

  if #args > 4 then
    error("if command: to many arguments")
  elseif args[3] ~= "as" then
    error("with command: invalid arguments")
  end

  local nodelist = parser:parse({"endwith"})
  parser:delete_first_token()

  return WithNode(nodelist, args[2], args[4])
end
