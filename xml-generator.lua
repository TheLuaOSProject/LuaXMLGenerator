local has_strbuf, strbuf = pcall(require, "string.buffer")

---@diagnostic disable: invisible
-- https://leafo.net/guides/setfenv-in-lua52-and-above.html
local setfenv = setfenv or function(fn, env)
    local i = 1
    while true do
        local name = debug.getupvalue(fn, i)
        if name == "_ENV" then
            debug.upvaluejoin(fn, i, (function() return env end), 1)
            break
        elseif not name then break end

        i = i + 1
    end

    return fn
end

local unpack = table.unpack or unpack

---@generic T: table
---@param x T
---@param copy_metatable boolean?
---@return T
local function deep_copy(x, copy_metatable)
    local tname = type(x)
    if tname == "table" then
        local new = {}
        for k, v in pairs(x) do
            new[k] = deep_copy(v, copy_metatable)
        end

        if copy_metatable then setmetatable(new, deep_copy(getmetatable(x), true)) end

        return new
    else return x end
end

---@param x table
---@return metatable
local function metatable(x)
    local mt = getmetatable(x) or {}
    setmetatable(x, mt)
    return mt
end

---@generic T
---@param x T[]
---@return T[]
local function stringable_array(x)
    metatable(x).__tostring = function (self)
        local parts = {}

        for i, v in ipairs(self) do
            parts[i] = tostring(v)
        end

        return table.concat(parts)
    end
    (metatable(x) --[[@as table]]).__name = "XML.StringableArray"

    return x
end

if has_strbuf then
    ---@generic T
    ---@param x T[]
    ---@return T[]
    function stringable_array(x)
        --[[@cast x table]]
        function x:tostring_stringbuf(buf)
            for i, v in ipairs(self) do
                buf:put(tostring(v))
            end
        end

        metatable(x).__tostring = function (self)
            --[[@cast self table]]
            local buf = strbuf.new(#x)
            self:tostring_stringbuf(buf)
            return buf:tostring()
        end
        (metatable(x) --[[@as table]]).__name = "XML.StringableArray"

        return x
    end
end

---@class xml-generator
local export = {
    ---Attributes that should not be sanitized
    no_sanitize = { ["style"] = true, ["script"] = true },

    ---Sets the value of the `lua` variable available in generators
    ---
    ---This is so if you use `declare_generator` you can use `lua` to access the whatever value is specified, usually `_G`
    ---@type table?
    lua = _G
}

---@class XML.Children
---@field [integer] XML.Node | string | fun(): XML.Node`

---@class XML.AttributeTable : XML.Children
---@field [string] string | boolean | number

---@class XML.Node
---@operator call(XML.AttributeTable): XML.Node
---@operator concat(XML.Node | string): XML.Node
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

---@generic T
---@param x T
---@return type | `T`
function export.typename(x)
    local mt = getmetatable(x)
    if mt and mt.__name then return mt.__name else return type(x) end
end
local typename = export.typename



local insert = table.insert
local concat = table.concat
local tostring = tostring
---@param node XML.Node | XML.Component
---@return string
function export.node_to_string(node)
    if typename(node) == "XML.Component" then return tostring(node) end

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

    for i, v in ipairs(node.children) do
        local tname = typename(v)
        if tname == "XML.Node" or tname == "XML.Component" or tname == "XML.StringableArray" then
            insert(parts, tostring(v))
        elseif tname == "function" then
            local f = coroutine.wrap(v)
            for elem in f do
                insert(parts, export.node_to_string(elem))
            end
        elseif tname == "table" and not (getmetatable(v) or {}).__tostring then
            for _, elem in ipairs(v) do
                insert(parts, sanitize_text(tostring(elem)))
            end
        else
            insert(parts, sanitize_text(tostring(v)))
        end
    end

    insert(parts, "</"..node.tag..">")

    return concat(parts)
end

if has_strbuf then
    ---@overload fun(node: XML.Node | XML.Component, buf: string.buffer): nil
    ---@param node XML.Node | XML.Component
    ---@return string
    function export.node_to_string(node, buf)
        if not buf then
            buf = strbuf.new()
            export.node_to_string(node, buf)
            return buf:tostring()
        end

        if typename(node) == "XML.Component" then
            return export.component_to_string(node, buf)
        end

        local sanitize = not export.no_sanitize[node.tag:lower()]
        local sanitize_text = sanitize and export.sanitize_text or function (...) return ... end

        buf:putf("<%s", node.tag)

        for k, v in pairs(node.attributes) do
            if type(v) == "boolean" then
                if v then buf:putf(" %s", k) end
            else
                buf:putf(" %s=\"%s\"", k, export.sanitize_attributes(tostring(v)))
            end
        end

        buf:put(">")


        for i, v in ipairs(node.children) do
            local tname = typename(v)
            
            if tname == "XML.StringableArray" then
                v:tostring_stringbuf(buf)
            elseif tname == "XML.Node" then
                export.node_to_string(v, buf)
            elseif tname == "XML.Component" then
                export.component_to_string(v, buf)
            elseif tname == "function" then
                local f = coroutine.wrap(v)
                for elem in f do
                    export.node_to_string(elem, buf)
                end
            elseif tname == "table" and not (getmetatable(v) or {}).__tostring then
                for _, elem in ipairs(v) do
                    buf:put(sanitize_text(tostring(elem)))
                end
            else
                buf:put(sanitize_text(tostring(v)))
            end
        end

        buf:putf("</%s>", node.tag)
    end
end

export.node_metatable = {
    ---@param self XML.Node
    ---@param attribs XML.AttributeTable | string | XML.Node
    ---@return XML.Node
    __call = function (self, attribs)
        local new = export.create_node(self.tag, deep_copy(self.attributes, true), deep_copy(self.children, true)) --[[@as XML.Node]]
        local tname = typename(attribs)
        if tname == "table" then
            for i, v in pairs(attribs) do
                if type(i) == "number" then
                    new.children[#new.children+1] = v
                else
                    new.attributes[i] = v
                end
            end
        else
            new.children[#new.children+1] = attribs --[[@as string|function]]
        end

        return new
    end;

    __tostring = export.node_to_string;
    __concat = function(self, x) return self(x) end;
    __name = "XML.Node";
}

---@overload fun(tag_name: "lua", attributes: XML.AttributeTable?, children: XML.Children?): _G
---@param tag_name string
---@param attributes XML.AttributeTable?
---@param children XML.Children?
---@return XML.Node
function export.create_node(tag_name, attributes, children)
    if tag_name == "lua" and export.lua then return export.lua end

    return setmetatable({
        tag = tag_name,
        children = children or {},
        attributes = attributes or {},
    }, export.node_metatable)
end

---@class XML.GeneratorTable
---@field lua _G
---@field [string] XML.Node
export.xml = setmetatable({}, {
    ---@param _ XML.GeneratorTable
    ---@param tag_name string
    __index = function(_, tag_name)
        return export.create_node(tag_name)
    end
})

---@generic T
---@param func fun(...: T): XML.Node
---@return fun(...: T): XML.Node
function export.declare_generator(func) return setfenv(func, export.xml) end

---Creates a style tag with the given lua table
---@param css { [string | string[]] : { [string | string[]] : (number | string | string[]) } }
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

---@param component XML.Component
---@return string
function export.component_to_string(component)
    local f = coroutine.create(component.context)

    ---@type XML.Node[]
    local arr = stringable_array {}
    local ok, res = coroutine.resume(f, component.attributes, table.unpack(component.children))
    if not ok then error(res) end
    table.insert(arr, res)

    while coroutine.status(f) ~= "dead" do
        ok, res = coroutine.resume(f)
        if not ok then error(res) end
        table.insert(arr, res)
    end

    return tostring(arr)
end

if has_strbuf then
    ---@overload fun(component: XML.Component, buf: string.buffer): nil
    ---@param component XML.Component
    ---@return string
    function export.component_to_string(component, buf)
        if not buf then
            local buf = strbuf.new()
            export.component_to_string(component, buf)
            return buf:tostring()
        end

        local f = coroutine.create(component.context)

        ---@type table
        local arr = stringable_array {}
        local ok, res = coroutine.resume(f, component.attributes, unpack(component.children))
        if not ok then error(res) end
        table.insert(arr, res)

        while coroutine.status(f) ~= "dead" do
            ok, res = coroutine.resume(f)
            if not ok then error(res) end
            table.insert(arr, res)
        end

        arr:tostring_stringbuf(buf)
    end
end

---@class XML.Component : XML.Node
---@field attributes { [string] : any } The attributes can be any type for `component`s, but not for `node`s
---@field context fun(args: { [string] : any }, children: XML.Children?): XML.Node?
export.component_metatable = {
    ---@param self XML.Component
    ---@param args { [string] : any, [integer] : XML.Children }
    __call = function (self, args)
        ---@type XML.Component
        local new = setmetatable({
            attributes  = deep_copy(self.attributes, true),
            children    = deep_copy(self.children or stringable_array {}, true),
            context     = self.context
        }, getmetatable(self))

        if type(args) == "table" and not (getmetatable(args) or {}).__tostring then
            for k, v in pairs(args) do
                if type(k) == "number" then
                    insert(new.children, v)
                else
                    new.attributes[k] = v
                end
            end
        else
            insert(new.children, args)
        end

        return new
    end;

    __tostring = export.component_to_string;
    __concat = function(self, x) return self(x) end;
    __name = "XML.Component";
}

--[[
```lua
local xml_generator = require("xml-generator")
local xml = xml_generator.xml

local my_component = xml_generator.component(function(args, ...)
    local number = args.number + 10

    coroutine.yield(xml.div {
        xml.h1 "Hello, World!";
        {...};
        xml.p("Number: "..number);
    })
end)

print(my_component {number=1}{
    xml.p "This is a child"
})
```
]]
---@param context fun(args: { [string] : any }, children: XML.Children): XML.Node?
---@return XML.Component
function export.component(context)
    return setmetatable({ attributes = {}, children = stringable_array {}, context = context }, export.component_metatable)
end

---@param ns string
---@param sep string?
---@return XML.GeneratorTable
function export.namespace(ns, sep)
    return setmetatable({ namespace = ns, seperator = sep or "-" }, {
        __index = function(self, tag_name)
            return export.create_node(self.namespace..self.seperator..tag_name)
        end
    })
end

---WILL NOT BE SANITIZED
---@param ... string
---@return string[]
function export.raw(...) return stringable_array { ... } end

return export
