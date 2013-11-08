require "leslie.settings"
require "leslie.utils"
require "leslie.class-leslie0"
require "leslie.parser"
require "leslie.tags"
require "leslie.loader_tags"
require "leslie.filters"

module("leslie", package.seeall)

version = "0.3b-pre"

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

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
    -- add the value copy by toontong
    self.context = shallowcopy(t) or {}
end

---
function Context:evaluate(filter)

    local start_char = filter:sub(1, 1)
    local TEMPLATE_STRING_IF_INVALID = leslie.settings.TEMPLATE_STRING_IF_INVALID

    if start_char == "\"" or start_char == "'" then
        do return filter:sub(2, -2) end
    end

    local new = self.context
    local filter = leslie.utils.split(filter, leslie.parser.VARIABLE_ATTRIBUTE_SEPARATOR)
    local last = table.remove(filter)

    if #filter > 0 then
        for i, var in ipairs(filter) do
            if i == 1 then
                if self.context[var] == nil then
                    do return TEMPLATE_STRING_IF_INVALID end
                end
                new = self.context[var]
            else
                if new[var] == nil then
                    do return TEMPLATE_STRING_IF_INVALID end
                end
                new = new[var]
            end
        end
    end

    if type(new) ~= "table" then
        do return TEMPLATE_STRING_IF_INVALID end
    end
    -- if new.has_key(last)
    if new[last] ~= nil then return new[last] end

    return new[last] or TEMPLATE_STRING_IF_INVALID
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

local _all_templ = {}
---
function loader(filename)
    if _all_templ[tostring(filename)] ~= nil then
        return _all_templ[tostring(filename)]
    end

    local file, err

    if #leslie.settings.TEMPLATE_DIRS > 0 then
        for _, path in ipairs(leslie.settings.TEMPLATE_DIRS) do
            file, err = io.open(path .."/".. filename)
            if file then break end
        end
    else
        file, err = io.open(filename)
    end

    if not file then
        error(err)
    end

    _all_templ[tostring(filename)] = Template(file:read("*a"))
    return _all_templ[tostring(filename)]
end
