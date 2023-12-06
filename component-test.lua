local xml_gen = require("xml-generator")
local xml = xml_gen.xml

math.randomseed(os.time())

local random_number = xml_gen.component(function(args, children)
    local min = args.min or 0
    local max = args.max or 100
    --remove these from the args so they dont show up in our HTML attributes later
    args.min = nil
    args.max = nil

    coroutine.yield(xml.p"This is a valid coroutine too!")

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
