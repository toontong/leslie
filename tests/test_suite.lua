require "leslie"
require "luaunit"

local t = [[{% if name %}Hello my name is {{ name }}.{% else %}Unknown name{% endif %}]]
local tokens_result = {
  { type = leslie.parser.TOKEN_BLOCK, contents = "if name" },
  { type = leslie.parser.TOKEN_TEXT, contents = "Hello my name is " },
  { type = leslie.parser.TOKEN_VAR, contents = "name" },
  { type = leslie.parser.TOKEN_TEXT, contents = "." },
  { type = leslie.parser.TOKEN_BLOCK, contents = "else" },
  { type = leslie.parser.TOKEN_TEXT, contents = "Unknown name" },
  { type = leslie.parser.TOKEN_BLOCK, contents = "endif" },
}
local nodelist_result = {
  leslie.tags.IfNode
}

local t2 = [[{% if name %}
    {# display this text if name is set #}
    Hello my name is {{ name }}.
{% else %}
    Unknown name
{% endif %}
]]

local tokens_result2 = {
  { type = leslie.parser.TOKEN_BLOCK, contents = "if name" },
  { type = leslie.parser.TOKEN_TEXT, contents = "    Hello my name is " },
  { type = leslie.parser.TOKEN_VAR, contents = "name" },
  { type = leslie.parser.TOKEN_TEXT, contents = ".\n" },
  { type = leslie.parser.TOKEN_BLOCK, contents = "else" },
  { type = leslie.parser.TOKEN_TEXT, contents = "    Unknown name\n" },
  { type = leslie.parser.TOKEN_BLOCK, contents = "endif" },
}

local t3 = [[{ no comment }{# some comment #}{% if name %}Hello {{ name }}!{% endif %}]]

local tokens_result3 = {
  { type = leslie.parser.TOKEN_TEXT, contents = "{ no comment }" },
  { type = leslie.parser.TOKEN_COMMENT, contents = "some comment" },
  { type = leslie.parser.TOKEN_BLOCK, contents = "if name" },
  { type = leslie.parser.TOKEN_TEXT, contents = "Hello " },
  { type = leslie.parser.TOKEN_VAR, contents = "name" },
  { type = leslie.parser.TOKEN_TEXT, contents = "!" },
  { type = leslie.parser.TOKEN_BLOCK, contents = "endif" },
}

TestToken = {}

function TestToken:setUp()
  self.token = leslie.parser.Token(leslie.parser.TOKEN_TEXT, "Hello my name is ")
end

function TestToken:test_initialize()
  assertEquals(self.token.token_type, leslie.parser.TOKEN_TEXT)
  assertEquals(self.token.contents, "Hello my name is ")
end

TestLexer = {}

function TestLexer:setUp()
  self.lexer = leslie.parser.Lexer()
end

function TestLexer:test_tokenize()
  local tokens = self.lexer:tokenize(t)

  assertEquals(#tokens, #tokens_result)

  for i, token in ipairs(tokens) do
    assertEquals(token.token_type, tokens_result[i].type)
    assertEquals(token.contents, tokens_result[i].contents)
  end
end

function TestLexer:test_tokenize_comments()
  local tokens = self.lexer:tokenize("{ no comment }{# some comment #}")

  assertEquals(#tokens, 2)
  assertEquals(tokens[1].contents, "{ no comment }")
  assertEquals(tokens[1].token_type, leslie.parser.TOKEN_TEXT)
end

function TestLexer:test_tokenize_comments2()
  local tokens = self.lexer:tokenize(t3)

  assertEquals(#tokens, #tokens_result)

  for i, token in ipairs(tokens) do
    assertEquals(token.token_type, tokens_result3[i].type)
    assertEquals(token.contents, tokens_result3[i].contents)
  end
end

TestLexer__future = {}

function TestLexer__future:setUp()
  self.lexer = leslie.parser.Lexer()
end


function TestLexer__future:test_tokenize()
  local tokens = self.lexer:tokenize(t2)

  assertEquals(#tokens, #tokens_result2)

  for i, token in ipairs(tokens) do
    assertEquals(token.token_type, tokens_result2[i].type)
    assertEquals(token.contents, tokens_result2[i].contents)
  end
end

-- test disable
TestLexer__future = nil

TestParser = {}

function TestParser:setUp()
  local lex = leslie.parser.Lexer()
  self.parser = leslie.parser.Parser(lex:tokenize(t))
end

function TestParser:test_parse()
  local nodelist = self.parser:parse()

  assertEquals(#nodelist.nodes, 1)

  for i, node in ipairs(nodelist.nodes) do
    assertEquals(node:instanceof(nodelist_result[i]), true)
  end
end

function TestParser:test_delete_first_token()
  local size = #self.parser.tokens

  self.parser:delete_first_token()
  assertEquals(#self.parser.tokens, size - 1)
end

function TestParser:test_prepend_token()
  local size = #self.parser.tokens
  local token = leslie.parser.Token(leslie.parser.TOKEN_TEXT, "Hello")

  self.parser:prepend_token(token)

  assertEquals(#self.parser.tokens, size + 1)
end

function TestParser:test_next_token()
  local size = #self.parser.tokens
  local token = leslie.parser.Token(leslie.parser.TOKEN_TEXT, "Hello")

  self.parser:prepend_token(token)

  local next = self.parser:next_token()

  assertEquals(next, token)
  assertEquals(next.contents, "Hello")
  assertEquals(next.token_type, leslie.parser.TOKEN_TEXT)
  assertEquals(#self.parser.tokens, size)
end

TestNodeList = {}

function TestNodeList:setUp()
  local lex = leslie.parser.Lexer()
  local parser = leslie.parser.Parser(lex:tokenize(t))
  self.nodelist = parser:parse()
end

function TestNodeList:test_nodelist()
  assertEquals(type(self.nodelist.nodes), "table")
  assertEquals(self.nodelist.class ~= nil, true)
  assertEquals(self.nodelist:instanceof(leslie.parser.NodeList), true)
end

function TestNodeList:test_extend()
  local size = #self.nodelist.nodes
  self.nodelist:extend(leslie.parser.Node())
  assertEquals(#self.nodelist.nodes, size + 1)
end

function TestNodeList:test_render()
  local c = leslie.Context({ name = "Leslie"})
  local c2 = leslie.Context()

  assertEquals(self.nodelist:render(c), "Hello my name is Leslie.")
  assertEquals(self.nodelist:render(c2), "Unknown name")
end

TestContext = {}

function TestContext:test_initialize()
  local t = { name = "Leslie" }
  local c = leslie.Context()
  local c2 = leslie.Context(t)

  assertEquals(#c.context, 0)
  assertEquals(c2.context, t)
end

function TestContext:test_evaluate()
  local c = leslie.Context({ name = "Leslie" })

  assertEquals(c:evaluate("name"), "Leslie")
end

function TestContext:test_evaluate2()
  local c = leslie.Context({ user = { name = "Leslie" }})

  assertEquals(c:evaluate("user.name"), "Leslie")
end

function TestContext:test_evaluate3()
  local c = leslie.Context({ user = { name = "Leslie" }})

  assertEquals(c:evaluate("\"Leslie\""), "Leslie")
end

function TestContext:test_evaluate4()
  local c = leslie.Context({ user = { name = "Leslie" }})

  assertEquals(c:evaluate("'Leslie'"), "Leslie")
end

function TestContext:test_filter()
  local c = leslie.Context({ users = {{ name = "Leslie" }}})
  local list = c:filter("users")

  assertEquals(list.context[1].name, "Leslie")
end

function TestContext:test_filter2()
  local c = leslie.Context({ users = { top = {{ user = { name = "Leslie" }}}}})
  local list = c:filter("users.top")

  assertEquals(list.context[1].user.name, "Leslie")
end

TestNode = {}

function TestNode:test_render()
  local n = leslie.parser.Node()

  assertEquals(n:render(), "")
end

TestTextNode = {}

function TestTextNode:setUp()
  self.node = leslie.parser.TextNode(" Leslie ")
end

function TestTextNode:test_initialize()
  assertEquals(self.node.str, " Leslie ")
end

function TestTextNode:test_render()
  assertEquals(self.node:render(), " Leslie ")
end

TestVariableNode = {}

function TestVariableNode:setUp()
  self.node = leslie.parser.VariableNode("user.name")
end

function TestVariableNode:test_initialize()
  assertEquals(self.node.filter_expression, "user.name")
end

function TestVariableNode:test_render()
  local c = leslie.Context({ user = { name = "Leslie"}})

  assertEquals(self.node:render(c), "Leslie")
end

TestIfNode = {}

function TestIfNode:setUp()
  local lex = leslie.parser.Lexer()
  local p = leslie.parser.Parser()
  p.tokens = lex:tokenize("Hello {{ user.name }}!")

  local nl_true = p:parse()
  p.tokens = lex:tokenize("Hello what's your name?")

  local nl_false = p:parse()
  local cond = "user.name"

  self.node = leslie.tags.IfNode(nl_true, nl_false, cond)
end

function TestIfNode:test_initialize()
  assertEquals(self.node.nodelist_true:instanceof(leslie.parser.NodeList), true)
  assertEquals(self.node.nodelist_false:instanceof(leslie.parser.NodeList), true)
  assertEquals(self.node.cond_expression, "user.name")
end

function TestIfNode:test_render_true()
  local c = leslie.Context({ user = { name = "Leslie"}})

  assertEquals(self.node:render(c), "Hello Leslie!")
end

function TestIfNode:test_render_false()
  local c = leslie.Context({ user = { name = nil }})

  assertEquals(self.node:render(c), "Hello what's your name?")
end

TestIfEqualNode = {}

function TestIfEqualNode:setUp()
  local lex = leslie.parser.Lexer()
  local p = leslie.parser.Parser()
  p.tokens = lex:tokenize("Hello {{ user1.name }} and {{ user2.name }}!")

  local nl_true = p:parse()
  p.tokens = lex:tokenize("Who is {{ user1.name }} and who is {{ user2.name }}?")

  local nl_false = p:parse()
  local var = "user1.name"
  local var2 = "user2.name"

  self.node = leslie.tags.IfEqualNode(nl_true, nl_false, var, var2, 0)
end

function TestIfEqualNode:test_initialize()
  assertEquals(self.node.nodelist_true:instanceof(leslie.parser.NodeList), true)
  assertEquals(self.node.nodelist_false:instanceof(leslie.parser.NodeList), true)
  assertEquals(self.node.var, "user1.name")
  assertEquals(self.node.var2, "user2.name")
  assertEquals(self.node.mode, 0)
end

function TestIfEqualNode:test_render_true()
  local c = leslie.Context({ user1 = { name = "Leslie"}, user2 = { name = "Leslie" }})

  assertEquals(self.node:render(c), "Hello Leslie and Leslie!")
end

function TestIfEqualNode:test_render_false()
  local c = leslie.Context({ user1 = { name = "Leslie" }, user2 = { name = "Django"}})

  assertEquals(self.node:render(c), "Who is Leslie and who is Django?")
end

function TestIfEqualNode:test_render_true2()
  local c = leslie.Context({ user1 = { name = "Leslie" }, user2 = { name = "Django"}})

  self.node.var2 = "\"Leslie\""
  assertEquals(self.node:render(c), "Hello Leslie and Django!")
  self.node.var = "user2.name"
  assertEquals(self.node:render(c), "Who is Leslie and who is Django?")
end

function TestIfEqualNode:test_render_false2()
  local c = leslie.Context({ user1 = { name = "Leslie" }, user2 = { name = "Django"}})

  self.node.var = "user2.name"
  self.node.var2 = "\"Leslie\""

  assertEquals(self.node:render(c), "Who is Leslie and who is Django?")
end

TestIfNotEqualNode = {}

function TestIfNotEqualNode:setUp()
  local lex = leslie.parser.Lexer()
  local p = leslie.parser.Parser()
  p.tokens = lex:tokenize("Hello {{ user1.name }} and {{ user2.name }}!")

  local nl_true = p:parse()
  p.tokens = lex:tokenize("Who is {{ user1.name }} and who is {{ user2.name }}?")

  local nl_false = p:parse()
  local var = "user1.name"
  local var2 = "user2.name"

  self.node = leslie.tags.IfEqualNode(nl_true, nl_false, var, var2, 1)
end

function TestIfNotEqualNode:test_initialize()
  assertEquals(self.node.nodelist_true:instanceof(leslie.parser.NodeList), true)
  assertEquals(self.node.nodelist_false:instanceof(leslie.parser.NodeList), true)
  assertEquals(self.node.var, "user1.name")
  assertEquals(self.node.var2, "user2.name")
  assertEquals(self.node.mode, 1)
end

function TestIfNotEqualNode:test_render_false()
  local c = leslie.Context({ user1 = { name = "Leslie"}, user2 = { name = "Leslie" }})

  assertEquals(self.node:render(c), "Who is Leslie and who is Leslie?")
end

function TestIfNotEqualNode:test_render_true()
  local c = leslie.Context({ user1 = { name = "Leslie" }, user2 = { name = "Django"}})

  assertEquals(self.node:render(c), "Hello Leslie and Django!")
end

function TestIfNotEqualNode:test_render_false2()
  local c = leslie.Context({ user1 = { name = "Leslie" }, user2 = { name = "Leslie"}})

  self.node.var2 = "\"Leslie\""

  assertEquals(self.node:render(c), "Who is Leslie and who is Leslie?")
end

function TestIfNotEqualNode:test_render_true2()
  local c = leslie.Context({ user1 = { name = "Leslie" }, user2 = { name = "Django"}})

  self.node.var2 = "\"Django\""

  assertEquals(self.node:render(c), "Hello Leslie and Django!")
end

TestForNode = {}

function TestForNode:setUp()
  local lex = leslie.parser.Lexer()
  local p = leslie.parser.Parser()
  p.tokens = lex:tokenize("{{ name }}\n")

  local nl = p:parse()
  p.tokens = lex:tokenize("no items")

  local nl_empty = p:parse()
  p.tokens = lex:tokenize("{% for char in name.chars %}{{ forloop.parentloop.counter }}.{{ forloop.counter }}.{{ char }}.{% endfor %}\n")
  self.nl_subloop = p:parse()
  p.tokens = lex:tokenize("x={{ x }}, y={{ y }};")
  self.nl_argloop = p:parse()

  self.node = leslie.tags.ForNode(nl, nl_empty, "names", {"name"})
end

function TestForNode:test_initialize()
  assertEquals(self.node.nodelist:instanceof(leslie.parser.NodeList), true)
  assertEquals(self.node.nodelist_empty:instanceof(leslie.parser.NodeList), true)
  assertEquals(self.node.filter_expression, "names")
  assertEquals(self.node.unpack_list[1], "name")
end

function TestForNode:test_render()
  local c = leslie.Context({ names = { "Leslie", "leslie", "LESLIE" }})

  assertEquals(self.node:render(c), "Leslie\nleslie\nLESLIE\n")
end

function TestForNode:test_render_empty()
  local c = leslie.Context({ names = nil })

  assertEquals(self.node:render(c), "no items")
end

function TestForNode:test_args()
  local c = leslie.Context({ points = { {1, 2}, {4, 2}, {6, 9} }})
  self.node.nodelist = self.nl_argloop
  self.node.filter_expression = "points"
  self.node.unpack_list = {"x", "y"}

  assertEquals(self.node:render(c), "x=1, y=2;x=4, y=2;x=6, y=9;")
end

function TestForNode:test_loopvars()
  local c = leslie.Context({
    names = {
      { chars = {"L","e","s","l","i","e"} },
      { chars = {"L","E","S","L","I","E"} }
    }
  })
  local result = "1.1.L.1.2.e.1.3.s.1.4.l.1.5.i.1.6.e.\n2.1.L.2.2.E.2.3.S.2.4.L.2.5.I.2.6.E.\n"
  self.node.nodelist = self.nl_subloop
  self.node.filter_expression = "names"
  self.node.unpack_list = {"name"}

  assertEquals(self.node:render(c), result)
end

TestWithNode = {}

function TestWithNode:setUp()
  local lex = leslie.parser.Lexer()
  local p = leslie.parser.Parser(lex:tokenize("Hello {{ user.name }}!"))
  local nl = p:parse()

  self.node = leslie.tags.WithNode(nl, "users.leslie", "user")
end

function TestWithNode:test_initialize()
  assertEquals(self.node.nodelist:instanceof(leslie.parser.NodeList), true)
  assertEquals(self.node.filter_expression, "users.leslie")
  assertEquals(self.node.alias, "user")
end

function TestWithNode:test_render()
  local c = leslie.Context({ users = { leslie = { name = "Leslie" }}})

  assertEquals(self.node:render(c), "Hello Leslie!")
end

TestFirstOfNode = {}

function TestFirstOfNode:setUp()
  self.vars = { "name", "name2", "\"default\"" }
  self.node = leslie.tags.FirstOfNode(self.vars)
end

function TestFirstOfNode:test_initialize()
  assertEquals(self.node.vars, self.vars)
end

function TestFirstOfNode:test_render()
  local c = leslie.Context({ name = "Leslie" })

  assertEquals(self.node:render(c), "Leslie")
end

function TestFirstOfNode:test_render2()
  local c = leslie.Context({ name = nil })

  assertEquals(self.node:render(c), "default")
end

function TestFirstOfNode:test_render3()
  local c = leslie.Context({ name = "", name2 = "LESLIE" })

  assertEquals(self.node:render(c), "LESLIE")
end

function TestFirstOfNode:test_render4()
  local c = leslie.Context({ name = "", name2 = 0 })
  
  self.node.vars[3] = "'default'"

  assertEquals(self.node:render(c), "default")
end

TestTemplate = {}

function TestTemplate:setUp()
  self.template = leslie.Template("Hello {{ name }}!")
end

function TestTemplate:test_initialize()
  assertEquals(self.template.nodelist:instanceof(leslie.parser.NodeList), true)
end

function TestTemplate:test_render()
  local c = leslie.Context({ name = "Leslie" })

  assertEquals(self.template:render(c), "Hello Leslie!")
end

function test_loader()
  local t = leslie.loader("template.txt")
  local c = leslie.Context({ name = "Leslie" })

  assertEquals(t:instanceof(leslie.Template), true)
  assertEquals(t:render(c), "Hello Leslie!\n")
end

TestFunctions = wrapFunctions('test_loader')

LuaUnit:run()
