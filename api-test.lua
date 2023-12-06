local xml_gen = require("xml-generator")
local xml = xml_gen.xml

local my_node = xml.div {id="my-div"} {
    xml.p {id="p-1"} "Hello World";
    xml.p {id="p-2"} "Hello World";
    xml.p {id="p-3"} "Hello World";
}

print(my_node.tag, my_node.attributes.id)

for i, child in ipairs(my_node.children) do
    print(i, child.tag, child.attributes.id)
end

-- print(my_node)
