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

-- local my_table = {
--     key = "value",
--     sub = {
--         key = "value",
--     }
-- }

-- local tbl = xml_gen.html_table(my_table, { "key", "sub" }, {
--     table = "my-table",
--     tr = "my-table-row",
--     td = "my-table-cell",
-- })

-- print(tbl)

-- local xml_gen = require("xml-generator")

-- local style = xml_gen.style {
--     [{ "body", "html" }] = {
--         margin = 0,
--         padding = 0,
--     },

--     body = {
--         background = "#000",
--         color = "#fff",
--     }

--     --etc
-- }

-- print(style)
