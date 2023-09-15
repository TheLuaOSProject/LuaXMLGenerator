-- https://leafo.net/guides/setfenv-in-lua52-and-above.html
local setfenv = setfenv or function(fn, env)
    local i = 1
    while true do
        local name = debug.getupvalue(fn, i)
        if name == "_ENV" then
            debug.upvaluejoin(fn, i, (function() return env end), 1)
            break
        elseif not name then
            break
        end

        i = i + 1
    end

    return fn
end


---@class xml-generator
local export = {
    sanitize_style = false
}

---@class XML.Children
---@field [integer] XML.Node | string

---@class XML.AttributeTable : XML.Children
---@field [string] string | boolean | number

---@class XML.Node
---@operator call(XML.AttributeTable): XML.Node
---@field tag string
---@field children XML.Children
---@field attributes XML.AttributeTable

---quotes are allowed in text, not in attributes
---@param str string
---@return string
function export.sanitize_text(str)
    return (str:gsub("[<>&]", {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;"
    }))
end

---@param str string
---@return string
function export.sanitize_attributes(str)
    return (export.sanitize_text(str):gsub("\"", "&quot;"):gsub("'", "&#39;"))
end

---@param x any
---@return type | "XML.Node" | string
function export.typename(x)
    local mt = getmetatable(x)
    if mt and mt.__name then
        return mt.__name
    else
        return type(x)
    end
end
local typename = export.typename

---@param node XML.Node
---@return string
function export.node_to_string(node)
    local sanitize = (not export.sanitize_style) and node.tag ~= "style"
    local sanitize_text = sanitize and export.sanitize_text or function (...) return ... end

    local html = "<"..node.tag

    for k, v in pairs(node.attributes) do
        if type(v) == "boolean" then
            if v then html = html.." "..k end
        else
            html = html.." "..k.."=\""..export.sanitize_attributes(tostring(v)).."\""
        end
    end

    html = html..">"

    for i, v in ipairs(node.children) do
        if type(v) ~= "table" then
            html = html..sanitize_text(tostring(v))
        else
            html = html..export.node_to_string(v)
        end
    end

    html = html.."</"..node.tag..">"

    return html
end

---@class XML.GeneratorTable
---@field lua _G
---@field [string] XML.Node

---@type XML.GeneratorTable
export.generator_metatable = setmetatable({}, {
    ---@param _ XML.GeneratorTable
    ---@param tag_name string
    __index = function(_, tag_name)
        --When used
        if tag_name == "lua" then return _G end

        ---@type XML.Node
        local node = {
            tag = tag_name,
            children = {},
            attributes = {}
        }
        return setmetatable(node, {
            ---@param self XML.Node
            ---@param attribs XML.AttributeTable | string | XML.Node
            ---@return XML.Node
            __call = function (self, attribs)
                local tname = typename(attribs)
                if tname == "table" then
                    for i, v in ipairs(attribs --[[@as (string | XML.Node | fun(): XML.Node)[] ]]) do
                        local tname = typename(v)
                        if tname == "function" then
                            ---@type fun(): XML.Node | string
                            v = coroutine.wrap(v)
                            for elem in v do self.children[#self.children+1] = elem end
                        else
                            self.children[#self.children+1] = v
                        end

                        attribs[i] = nil
                    end

                    for key, value in pairs(attribs --[[@as { [string] : string | boolean | number }]]) do
                        self.attributes[key] = value
                    end
                else self.children[#self.children+1] = tname == "XML.Node" and attribs or tostring(attribs) end

                return self
            end;

            __tostring = export.node_to_string
        })
    end
})


---Usage:
--[=[
```lua
local generate_html = require("html")

local str = generate_html(function()
    return html {
        head {
            title "Hello"
        },
        body {
            div { id = "main" } {
                h1 "Hello",
                img { src = "http://leafo.net/hi" }
                p [[This is a paragraph]]
            }
        }
    }
end)

```
]=]
---@param ctx fun(html: XML.GeneratorTable): XML.Node
---@return XML.Node
function export.generate_node(ctx) return ctx(export.generator_metatable) end

---@generic T
---@param func fun(...: T): XML.Node
---@return fun(...: T): XML.Node
function export.declare_generator(func) return setfenv(func, export.generator_metatable) end

---@param ctx fun(html: XML.GeneratorTable): table
---@return string
function export.generate(ctx) return tostring(export.generate_node(ctx)) end

---Turns a lua table into an html table, recursively, with multiple levels of nesting
---@param tbl table
---@return XML.Node
function export.html_table(tbl)
    return export.generate_node(function(xml)
        return xml.table {
            function ()
                local function getval(v)
                    local tname = typename(v)
                    if tname == "XML.Node" then return v end

                    if typename(v) ~= "table" or (getmetatable(v) or {}).__tostring then
                        return tostring(v)
                    end

                    return export.html_table(v)
                end

                for i, v in ipairs(tbl) do
                    coroutine.yield (
                        xml.tr {
                            xml.td(tostring(i)),
                            xml.td(getval(v)),
                        }
                    )

                    tbl[i] = nil
                end

                for k, v in pairs(tbl) do
                    coroutine.yield (
                        xml.tr {
                            xml.td(tostring(k)),
                            xml.td(getval(v)),
                        }
                    )
                end
            end
        }
    end)
end

---@alias OptionalStringCollection string | string[]
---@param css { [OptionalStringCollection] : { [OptionalStringCollection] : (OptionalStringCollection) } }
---@return XML.Node
function export.style(css)
    local css_str = ""
    for selector, properties in pairs(css) do
        if type(selector) == "table" then selector = table.concat(selector, ", ") end

        css_str = css_str..selector.." {\n"
        for property, value in pairs(properties) do
            if type(value) == "table" then value = table.concat(value, ", ") end

            css_str = css_str.."    "..property..": "..value..";\n"
        end
        css_str = css_str.."}\n"
    end

    return export.generate_node(function(xml) return xml.style(css_str) end)
end


return export
