-- https://github.com/manoelcampos/xml2lua
local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")

local function parse(xml)
  local tree = handler:new()
  local xmlparser = xml2lua.parser(tree)
  xmlparser:parse(xml)
  if tree.root.xml then
    return tree.root.xml
  else
    return tree.root
  end
end

return parse