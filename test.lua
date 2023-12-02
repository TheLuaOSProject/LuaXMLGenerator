local xml_gen = require("xml-generator")
local xml = xml_gen.xml

local test = xml.div {key="value"}

print(xml_gen.node_to_string(test))
