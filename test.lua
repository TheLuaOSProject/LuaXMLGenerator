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
    };

    xml_gen.raw [[
        <script>
            console.log("Hello, World!");
        </script>
    ]]
}

print(doc)
