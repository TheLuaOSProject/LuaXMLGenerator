local xml = require("xml2lua")
local parser = xml.parser(require("xmlhandler.tree"))

---@class Element.Attribute
---@field name string
---@field url string

---@class Element
---@field attributes Element.Attribute[]
---@field categories string[]
---@field description string

---@param filename string
---@return { [string]: Element }
return function(filename)
    ---@type string
    local contents do
        local file = assert(io.open(filename, "r"))
        contents = file:read("*a")
        file:close()
    end

    parser:parse(contents)

    local BASE_URL = "https://html.spec.whatwg.org/multipage/"

    local body = parser.handler.root.table.tbody

    local data = {}
    for _, row in ipairs(body.tr) do
        local row_data = nil
        for index, cell in pairs(row) do
            if index == "th" then
                io.stderr:write(xml.toString(cell), '\n')
                io.stderr:write("-----------\n")
                local txt = ((cell.code or {}).a or {})[1]
                if not txt then goto next end
                row_data = {}
                data[txt] = row_data
            else
                if not row_data then goto next end

                --#region Description
                local desc = cell[1]
                do
                    --for example:
                    --[[
                    Contact information for a page or <code id="elements-3:the-article-element"><a href="sections.html#the-article-element">article</a></code> element
                ]]
                    if type(desc) == "table" then
                        row_data.description = xml.toXml(desc, "lol-ignore-this")
                        row_data.description = row_data.description:gsub('<a href="', '<a href="' .. BASE_URL)
                    else
                        row_data.description = desc
                    end
                end
                --#endregion

                --#region Categories
                do
                    local cats = cell[2]
                    row_data.categories = {}

                    if type(cats) == "table" then
                        for _, cat in ipairs(cats.a) do
                            if cat == "none" or cat == ";" or cat == "*" then goto next end
                            table.insert(row_data.categories, cat[1])
                        end
                    else
                        if cats == "none" or cats == ";" or cats == "*" then goto next end
                        table.insert(row_data.categories, cats)
                    end

                    ::next::
                end
                --#endregion

                --#region Parents
                do
                    local parents = cell[3]
                    --ignore
                end
                --#endregion

                --#region Children
                do
                    local children = cell[4]
                    --ignore
                end
                --#endregion

                --#region Attributes
                do
                    local attrs = cell[5]
                    row_data.attributes = {}

                    -- xml.printable(attrs)

                    if type(attrs) == "table" then
                        for i, attr in pairs(attrs) do
                            if attr == ';' then goto next end

                            local whole_attribute = attr
                            attr = whole_attribute[1]
                            if type(attr) == "table" then
                                attr = attr.a
                                attr = {
                                    name = attr[1],
                                    url = attr._attr.href and BASE_URL .. attr._attr.href or nil
                                }
                            else
                                if not attr then goto next end
                                attr = {
                                    name = attr,
                                    url = whole_attribute._attr.href and BASE_URL .. whole_attribute._attr.href or nil
                                }
                            end

                            table.insert(row_data.attributes, attr)

                            ::next::
                        end
                    end
                end
                --#endregion
            end
            ::next::
        end
    end

    return data
end
