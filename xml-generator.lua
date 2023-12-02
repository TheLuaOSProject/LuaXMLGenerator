---@diagnostic disable: invisible
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
    ---Attributes that should not be sanitized
    no_sanitize = { ["style"] = true, ["script"] = true },

    ---If true, the `lua` tag will be replaced with `_G`, so doing `xml.lua` will return the global table
    ---
    ---This is so if you use `declare_generator` you can use `lua` to access the global table
    lua_is_global = true
}

---@class XML.Children
---@field [integer] XML.Node | string

---@class XML.AttributeTable : XML.Children
---@field [string] string | boolean | number

---@class XML.Node
---@operator call(XML.AttributeTable): XML.Node
---@field private tag string
---@field private children XML.Children
---@field private attributes XML.AttributeTable

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

---@generic T
---@param x T
---@return type | `T`
function export.typename(x)
    local mt = getmetatable(x)
    if mt and mt.__name then
        return mt.__name
    else
        return type(x)
    end
end
local typename = export.typename

local insert = table.insert
local concat = table.concat
local tostring = tostring
---@param node XML.Node
---@return string
function export.node_to_string(node)
    local sanitize = not export.no_sanitize[node.tag:lower()]
    local sanitize_text = sanitize and export.sanitize_text or function (...) return ... end

    local parts = { "<", node.tag }

    for k, v in pairs(node.attributes) do
        if type(v) == "boolean" then
            if v then insert(parts, " "..k) end
        else
            insert(parts, " "..k.."=\""..export.sanitize_attributes(tostring(v)).."\"")
        end
    end

    insert(parts, ">")

    for _, v in ipairs(node.children) do
        if type(v) ~= "table" then
            insert(parts, sanitize_text(tostring(v)))
        else
            insert(parts, export.node_to_string(v))
        end
    end

    insert(parts, "</"..node.tag..">")

    return concat(parts)
end


---@class XML.GeneratorTable
---@field lua _G
---@field [string] XML.Node
export.xml = setmetatable({}, {
    ---@param _ XML.GeneratorTable
    ---@param tag_name string
    __index = function(_, tag_name)
        if tag_name == "lua" and export.lua_is_global then return _G end

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
                            v = coroutine.wrap(v --[[@as function]])
                            for elem in v do self.children[#self.children+1] = elem end
                        else
                            self.children[#self.children+1] = v --[[@as string | XML.Node]]
                        end

                        attribs[i] = nil
                    end

                    for key, value in pairs(attribs --[[@as { [string] : string | boolean | number }]]) do
                        self.attributes[key] = value
                    end
                else
                    self.children[#self.children+1] = (tname == "XML.Node" and attribs or tostring(attribs)) --[[@as string | XML.Node]]
                end

                return self
            end;

            __tostring = export.node_to_string;

            __name = "XML.Node";
        })
    end
})

---@generic T
---@param func fun(...: T): XML.Node
---@return fun(...: T): XML.Node
function export.declare_generator(func) return setfenv(func, export.xml) end

---Turns a lua table into an html table, recursively, with multiple levels of nesting
---@generic TKey, TValue
---@param tbl { [TKey] : TValue },
---@param order TKey[]?
---@return XML.Node
function export.html_table(tbl, order)
    local xml = export.xml
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

            if order ~= nil then
                for i, v in ipairs(order) do
                    local val = tbl[v]
                    coroutine.yield (
                        xml.tr {
                            xml.td(tostring(v)),
                            xml.td(getval(val))
                        }
                    )
                end
            else
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
        end
    }
end

---Creates a style tag with the given lua table
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

    return export.xml.style(css_str)
end


return export
