package = "LuaXMLGenerator"
version = "0.2.3-1"
source = {
   url = "git+https://github.com/Frityet/LuaXMLGenerator",
   tag = "0.2.3"
}
description = {
   summary = "DSL to generate XML/HTML",
   homepage = "https://github.com/Frityet/LuaXMLGenerator",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.5"
}
build = {
   type = "builtin",
   modules = {
      ["xml-generator"] = "xml-generator.lua"
   }
}
