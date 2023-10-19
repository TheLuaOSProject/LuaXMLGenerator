#!/usr/bin/env lua

local data = require("parse-data") "items-raw.html"

---@alias WriteFunction fun(...: string): WriteFunction
---@alias WriteLineFunction fun(...: string): WriteFunction

---@type WriteFunction
local function w(...)
    io.write(...)
    return w
end

---@type WriteLineFunction
local function wl(...)
    io.write(...)
    io.write "\n"
    return wl
end

for k, v in pairs(data) do
    w "--[[# <code>" (k) '</code>\n'

    wl "## Description" (v.description) '\n'

    w (#v.categories > 0 and "## Categories" or "")
    for _, cat in ipairs(v.categories) do
        w "- " (cat) '\n'
    end

    w "]]\n"


    w "---@class HTMLElement." (k) ' : ' "XML.Node\n"
    for _, cat in ipairs(v.attributes) do
        if cat.name == "global" then goto next end
        w "---@field " (cat.name) " any " "[Documentation](" (cat.url or "") ")\n"
        ::next::
    end

    w "export.xml."(k)'=''export.xml.'(k) '\n\n'
end
