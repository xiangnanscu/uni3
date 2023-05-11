local get_payload = require("xodel.alioss").get_payload

local function main(request)
  local opts = request.get_post_data()
  return get_payload(opts)
end

return main
