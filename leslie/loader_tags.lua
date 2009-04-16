require "leslie.class-leslie0"

module("leslie.tags", package.seeall)

local function check_include_path(path)
    if path:sub(1, 1) ~= "/" and
       path:sub(3, 3) ~= "/" then
        do return false end
    end
    
    -- check ../ or ./
    
    return true
end

class("IncludeNode", _M) (leslie.parser.Node)

---
function IncludeNode:initialize(template_name)
    self.template_name = template_name
end

---
function IncludeNode:render(context)
	local name = context:evaluate(self.template_name)

    return leslie.loader(name):render(context)
end

---
function do_include(parser, token)
    local args = token:split_contents()
    
    return IncludeNode(args[2])
end

---
function do_ssi(parser, token)
    local args = token:split_contents()
    local template_path = args[2]
    
    assert(check_include_path(template_path), "Path must be specified using an absolute path")
    
    if not leslie.ALLOWED_INCLUDE_ROOTS then
        error("SSI includes not allowed - check leslie.ALLOWED_INCLUDE_ROOTS variable")
    end
    
    if args[3] == "parsed" then
        do return leslie.loader(template_path) end
    else
        local file, err = io.open(template_path, "r")

        if err then
            error("SSI include " .. template_path .. " not found")
        end
        
        do return leslie.parser.TextNode(file:read("*a")) end
    end
end

local register_tag = leslie.parser.register_tag

register_tag("include")
register_tag("ssi")
