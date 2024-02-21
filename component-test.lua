local xml_gen = require("xml-generator")
local xml = xml_gen.xml

math.randomseed(os.time())

local header = xml_gen.component(function (args, kids)
    return xml.head {
        xml.title {args.title};
        xml.meta {
            name="viewport",
            content="width=device-width, initial-scale=1"
        };
        kids;
        args.css_framework;
    }
end)

local tw = xml_gen.namespace "tw"

local doc = xml.html {charset="utf8"} {
    header {title="Hello, World!", css_framework=xml.link {rel="stylesheet", href="..."}} {
        xml.script {src="index.lua"};
        xml.br;
    };

    xml.body {
        xml.h1 {class="text-center"} "Fritsite";
        xml.main {class="container"} {
            xml.p "Hello, World!";
            xml.button {onclick="say_hi()"} "Say Hi!";
        };

        tw.div {id="test div"} "hello"
    };
}


print(doc)
