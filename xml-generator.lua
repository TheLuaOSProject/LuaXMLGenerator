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

---@class XML.Node
---@field tag string
---@field children (XML.Node | string | fun(): XML.Node)[]
---@field attributes { [string] : (string | boolean) }

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
            html = html .. " " .. k .. "=\"" .. export.sanitize_attributes(v) .. "\""
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

---@generic T
---@param fn T
---@return T
function export.declare_xml_generator(fn)
    local tbl = setmetatable({}, {
        ---@param self table
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
                        export.declare_xml_generator(v)
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
                    ---@param children (XML.Node | string | fun(): XML.Node)[]
                    __call = function(self, children)
                        if type(children) ~= "table" then
                            children = { tostring(children) }
                        end

                        for _, v in ipairs(children) do
                            if type(v) == "function" then
                                export.declare_xml_generator(v)
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

    setfenv(fn, tbl)
    return fn
end

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
---@param ctx fun(): table
---@return string
function export.generate_xml(ctx)
    return export.node_to_string(export.declare_xml_generator(ctx)())
end

---@param ctx fun(): table
---@return XML.Node
function export.generate_xml_node(ctx)
    return export.declare_xml_generator(ctx)()
end

---Turns a lua table into an html table, recursively, with multiple levels of nesting
---@param tbl table
---@return XML.Node
function export.table(tbl)
    ---@diagnostic disable: undefined-global
    return table {
        function()
            local function getval(v)
                if type(v) ~= "table" or (getmetatable(v) or {}).__tostring then
                    return tostring(v)
                end
                return html_table(v)
            end

            for i, v in ipairs(tbl) do
                yield(
                    tr {
                        td(tostring(i)),
                        td(getval(v)),
                    }
                )

                tbl[i] = nil
            end

            for k, v in pairs(tbl) do
                yield(
                    tr {
                        td(tostring(k)),
                        td(getval(v)),
                    }
                )
            end
        end
    }
    ---@diagnostic enable: undefined-global
end

export.declare_xml_generator(export.table)

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

    return export.generate_xml_node(function()
        ---@diagnostic disable: undefined-global
        return style(css_str)
        ---@diagnostic enable: undefined-global
    end)
end

return export
