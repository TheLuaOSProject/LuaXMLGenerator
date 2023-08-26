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
local export = {}

---@class XML.Children
---@field [integer] XML.Node | string | fun(): XML.Node

---@class XML.AttributeTable : XML.Children
---@field [string] string | boolean | number

---@class XML.Node
---@operator call(XML.Children): XML.Node
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
---@return type | string
local function typename(x)
    local mt = getmetatable(x)
    if mt and mt.__type then
        return mt.__type
    else
        return type(x)
    end
end

---@param node XML.Node
---@return string
function export.node_to_string(node)
    local html = "<" .. node.tag

    for k, v in pairs(node.attributes) do
        if type(v) == "boolean" then
            if v then html = html .. " " .. k end
        else
            html = html .. " " .. k .. "=\"" .. export.sanitize_attributes(tostring(v)) .. "\""
        end
    end

    html = html .. ">"

    for i, v in ipairs(node.children) do
        if type(v) ~= "table" then
            html = html .. export.sanitize_text(tostring(v))
        else
            html = html .. export.node_to_string(v)
        end
    end

    html = html .. "</" .. node.tag .. ">"

    return html
end

---@class XML.GeneratorTable
---@field [string] fun(attributes: XML.AttributeTable | string | XML.Node): XML.Node

---@type XML.GeneratorTable
export.generator_metatable = setmetatable({}, {
    ---@param self XML.GeneratorTable
    ---@param tag_name string
    __index = function(self, tag_name)
        ---@param attributes { [string] : string, [integer] : (XML.Node | string | fun(): XML.Node) } | string
        ---@return table | fun(children: (XML.Node | string | fun(): XML.Node)[]): XML.Node
        return function(attributes)
            ---@type XML.Node
            local node = {
                tag = tag_name,
                children = {},
                attributes = {}
            }

            --if we have a situation such as
            --[[
                tag "string"
            ]]
            --
            --then the content is the `string`
            local tname = typename(attributes)
            if tname ~= "table" and tname ~= "HTML.Node" then
                node.attributes = attributes and { tostring(attributes) } or {}
            elseif tname == "XML.Node" then
                ---local tag = div { p "hi" }
                ---div(tag)
                node.children = { attributes }
                attributes = {}
            else
                node.attributes = attributes --[[@as any]]
            end

            for i, v in ipairs(node.attributes) do
                if type(v) == "function" then
                    v = coroutine.wrap(v)
                    for sub in v do
                        node.children[#node.children + 1] = sub
                    end
                else
                    node.children[#node.children + 1] = v
                end

                node.attributes[i] = nil
            end

            return setmetatable(node, {
                __type = "XML.Node",

                __tostring = export.node_to_string,

                ---@param self XML.Node
                ---@param children XML.Children
                __call = function(self, children)
                    if type(children) ~= "table" then
                        children = { tostring(children) }
                    end

                    for _, v in ipairs(children) do
                        if type(v) == "function" then
                            v = coroutine.wrap(v)
                            for sub in v do
                                self.children[#self.children + 1] = sub
                            end
                        else
                            self.children[#self.children + 1] = v
                        end
                    end

                    return self
                end
            })
        end
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

---@param ctx fun(html: XML.GeneratorTable): table
---@return string
function export.generate(ctx) return tostring(export.generate_node(ctx)) end

---Turns a lua table into an html table, recursively, with multiple levels of nesting
---@param tbl table
---@return XML.Node
function export.html_table(tbl)
    return export.generate_node(function(xml)
        return xml.table {
            function()
                local function getval(v)
                    if type(v) ~= "table" or (getmetatable(v) or {}).__tostring then
                        return tostring(v)
                    end
                    return export.html_table(v)
                end

                for i, v in ipairs(tbl) do
                    coroutine.yield(
                        xml.tr {
                            xml.td(tostring(i)),
                            xml.td(getval(v)),
                        }
                    )

                    tbl[i] = nil
                end

                for k, v in pairs(tbl) do
                    coroutine.yield(
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

        css_str = css_str .. selector .. " {\n"
        for property, value in pairs(properties) do
            if type(value) == "table" then value = table.concat(value, ", ") end

            css_str = css_str .. "    " .. property .. ": " .. value .. ";\n"
        end
        css_str = css_str .. "}\n"
    end

    return export.generate_node(function(xml) return xml.style(css_str) end)
end

return export
