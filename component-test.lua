local xml_gen = require("xml-generator")
local xml = xml_gen.xml
local tw = xml_gen.namespace "tw"
math.randomseed(os.time())

local header = xml_gen.component(function (args, kids)
    return xml.head {
        xml.title(args.title);
        xml.meta {
            name="viewport",
            content="width=device-width, initial-scale=1"
        };
        kids;
        args.css_framework;
    }
end)

local random_number = xml_gen.component(function (args)
    return xml.p(math.random(args.min, args.max))
end)


local yield = coroutine.yield
local doc = xml_gen.declare_generator(function ()
---@diagnostic disable: undefined-global
    return html {charset="utf8"} {
        header {title="Hello, World!", css_framework=link {rel="stylesheet", href="..."}};

        body {
            h1 {class="text-center"} "Fritsite";
            main {class="container"} {
                p "Hello, World!";
                button {onclick="say_hi()"} "Say Hi!";
            };

            function ()
                for i = 1, 10 do
                    yield(random_number {id="rn-"..i} {min=1, max=100})
                end
            end;

            tw.div {id="test div"} "hello"
        };
    }
---@diagnostic enable: undefined-global
end)


print(doc())
