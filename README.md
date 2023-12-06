# LuaXMLGenerator

Library to easily generate XML with a clean Lua DSL.

## Installation

```bash
luarocks install luaxmlgenerator
```

## Usage

```lua
local xml_gen = require("xml-generator")
local xml = xml_gen.xml

local doc = xml.html {charset="utf-8", lang="en"} {
    xml.head {
        xml.title "Hello World"
    },
    xml.body {
        xml.h1 "Hello World",

        xml.div {id="numbers"} {
            function() --run as a coroutine
                for i = 1, 10 do
                    coroutine.yield(xml.p(i))
                end
            end
        }
    }
}

print(doc)
```

## Options

### `xml_gen.no_sanitize`
Table of tags that should not be sanitized. By default, it contains `script` and `style`.

```lua
local xml_gen = require("xml-generator")
xml_gen.no_sanitize["mytag"] = true

local doc = xml_gen.xml {
    xml.mytag [[
        Thsi will not be sanitized! <><><><><><%%%<>%<>%<>% you can use all of this!
    ]]
}

```

### `xml_gen.lua_is_global`

By default, within `xml_gen.xml` there is a special key called `lua` which just allows for `_G` to be accessed. This is useful if you use `xml_gen.declare_generator`, which overloads the `_ENV` (`setfenv` on 5.1), where the `_G` would not be ordinarily accessible.

```lua
local xml_gen = require("xml-generator")

local gen = xml_gen.declare_generator(function()
    return html {
        head {
            title "Hello World";
        };

        body {
            p { "The time of generation is ", lua.os.date() }
        };
    }
end)

print(gen())
```

## Components

Using `xml_gen.component` you can create your own components. Here is an example of a `random_number` component
```lua
---@param context fun(args: { [string] : any }, children: XML.Children): XML.Node?
---@return XML.Component
function export.component(context)
```

```lua
local xml_gen = require("xml-generator")
local xml = xml_gen.xml

math.randomseed(os.time())

local random_number = xml_gen.component(function(args, children)
    local min = args.min or 0
    --remove these from the args so they dont show up in our HTML attributes later
    args.min = nil
    local max = args.max or 100
    args.max = nil

    coroutine.yield(xml.p "This is a valid coroutine too!")

    return xml.span(args) {
        math.random(min, max),
        children --children is a table of all the children passed to the component, this may be empty
    }
end)

local doc = xml.html {
    xml.body {
        random_number {min = 0, max = 100};
        random_number {max=10} {
            xml.p "This is inside the span!"
        };
        random_number;
    }
}

print(doc)
```

## Utilities

### `xml_gen,declare_generator`
```lua
---@generic T
---@param func fun(...: T): XML.Node
---@return fun(...: T): XML.Node
function export.declare_generator(func)
```

Allows you to create a function in which the `_ENV` is overloaded with the `xml` table. This allows you to write XML more concisely (see example above).

### `xml_gen.html_table`
```lua
---@generic TKey, TValue
---@param tbl { [TKey] : TValue },
---@param order TKey[]?
---@param classes { table: string?, tr: string?, td: string? }?
---@return XML.Node
function export.html_table(tbl, order, classes)
```

Creates an HTML table based off a lua table. This is unstyled, so you will need to add your own CSS.

```lua

local my_table = {
    key = "value",
    sub = {
        key = "value",
    }
}

local tbl = xml_gen.html_table(my_table, { "key", "sub" }, {
    table = "my-table",
    tr = "my-table-row",
    td = "my-table-cell",
})

print(tbl)

```

### `xml_gen.style`
```lua
---@param css { [string | string[]] : { [string | string[]] : (number | string | string[]) } }
---@return XML.Node
function export.style(css)
```

Creates an HTML `style` tag with the given table

```lua
local xml_gen = require("xml-generator")

local style = xml_gen.style {
    [{ "body", "html" }] = {
        margin = 0,
        padding = 0,
    },

    body = {
        background = "#000",
        color = "#fff",
    }

    --etc
}

print(style)
```

## API

You do not need to generate XML with this library, instead, you can use an `XML.Node` as its own object.

```lua
---@class XML.Children
---@field [integer] XML.Node | string | fun(): XML.Node

---@class XML.AttributeTable : XML.Children
---@field [string] string | boolean | number

---@class XML.Node
---@operator call(XML.AttributeTable): XML.Node
---@field tag string
---@field children XML.Children
---@field attributes XML.AttributeTable

---@class XML.Component : XML.Node
---@field attributes { [string] : any } The attributes can be any type for `component`s, but not for `node`s
---@field context fun(args: { [string] : any }, children: XML.Children): XML.Node?

```

### `XML.Node`

```lua
local xml_gen = require("xml-generator")
local xml = xml_gen.xml

local my_node = xml.div {id="my-div"} {
    xml.p {id="p-1"} "Hello World";
    xml.p {id="p-2"} "Hello World";
    xml.p {id="p-3"} "Hello World";
}

print(my_node.tag) --div
print(my_node.attributes.id) --my-div

for i, child in ipairs(my_node.children) do
    print(i, child.tag, child.attributes.id)
end

print(my_node)
```

`attributes` and `children` can be empty, but will never be `nil`.

`tag` will be `nil` if the node is a `component`.
