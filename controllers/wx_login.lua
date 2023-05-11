local wx = require("xodel.wx")
local Usr = require("models.models").Usr

local function main(request)
  local data = wx.jscode2session(request.get_post_data().code)
  local openid = data.openid
  local user = Usr:select("id", "nickname", "avatar", "openid", "permission"):get_or_create { openid = openid }
  request.session.user = user
  return user
end

return main
