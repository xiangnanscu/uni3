local utils = require("xodel.utils")
local wx = require("xodel.wx")


-- https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api/phonenumber/phonenumber.getPhoneNumber.html
local function main(request)
  return wx.get_phone_number(request.get_post_data().code)
end

return main
