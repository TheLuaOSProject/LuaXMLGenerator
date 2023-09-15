local xml_gen = require("xml-generator")
local xml = xml_gen.xml

---Table -> Tree using &ltdetails&gt and &ltsummary&gt
---@param tbl table
---@return XML.Node
local function tree(tbl)
    return xml.div {
        function()
            local function getval(v)
                local tname = xml_gen.typename(v)
                if tname == "XML.Node" then return v, false end

                if tname ~= "table" or (getmetatable(v) or {}).__tostring then
                    return xml.p(tostring(v)), false
                end

                return tree(v), true
            end

            for i, v in ipairs(tbl) do
                local val, is_tree = getval(v)
                if is_tree then
                    coroutine.yield(
                        xml.details {
                            xml.summary(tostring(i)),
                            val
                        }
                    )
                else
                    coroutine.yield(
                        xml.table {
                            xml.tr {
                                xml.td(tostring(i)),
                                xml.td(val),
                            }
                        }
                    )
                end

                tbl[i] = nil
            end

            for k, v in pairs(tbl) do
                local val, is_tree = getval(v)
                if is_tree then
                    coroutine.yield(
                        xml.details {
                            xml.summary(tostring(k)),
                            val
                        }
                    )
                else
                    coroutine.yield(
                        xml.table {
                            xml.tr {
                                xml.td(tostring(k)),
                                xml.td(val),
                            }
                        }
                    )
                end
            end
        end
    }
end


local doc = xml.html { charset = "utf8" } {
    xml.head {
        xml.title "Hello, World!",
        xml_gen.style {
            ["details > div"] = {
                ["margin-left"] = "10px"
            }
        }
    },

    xml.body {
        xml.div { id = "numbers" } {
            tree {
                key = "value",
                sub = {
                    key = "value"
                },

                array = { 1, 2, 3, 4, 5 }
            }
        }
    }
}

print(doc)
