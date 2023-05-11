local http = require("xodel.http")
local function main(request)
  -- https://open.weixin.qq.com/connect/qrconnect?appid=wx1cec07ab49981256&redirect_uri=http://zzb.jahykj.cn/oauth&response_type=code&scope=snsapi_login&state=XXDDDS#wechat_redirect
  local query = request.get_uri_args() -- {code:xx,state:xx}
  -- {
  --   /*7f70db8d1dd8*/
  --   body         : {
  --     /*7f70db8d1f28*/
  --     access_token : "66_L7_GeuHNzr2D2EVc6VEUM9j68X7M841JMt6V9s1hkvlBBnpGm2BVEyM2YAeDpr75zCEzK_MGratI8gb1jBvcICXf8YGnuS6Di05OnIs0MtM",
  --     expires_in   : 7200,
  --     openid       : "ou8IF57AUFyrDvhbSKZL8qIvlqx4",
  --     refresh_token: "66_0_1P_Io15cBeMbjwTnbxhXeCCcwDQ8t2jfb04-Wuic9oo1jw-9Uj6eTge8wyBchWqhmFVgHrB5pwiPgGY2owOMWJ54XI9YfWjzNieM2RjzE",
  --     scope        : "snsapi_login",
  --     unionid      : "oCtsg5kguGQ8zYCuQG4P-EvC182k",
  --   },
  --   body_reader  : "function: 0x7f70dba9ae18",
  --   has_body     : true,
  --   headers      : {
  --     /*7f70db8d1520*/
  --     "Content-Length": "380",
  --     "Content-Type"  : "text/plain",
  --     Connection      : "keep-alive",
  --     Date            : "Wed, 08 Mar 2023 07:32:58 GMT",
  --   },
  --   read_body    : "function: 0x7f70dba82378",
  --   read_trailers: "function: 0x7f70dba82430",
  --   reason       : "OK",
  --   status       : 200,
  -- }
  local res = http.get(request.format(
    "https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code",
    request.getenv('WX_OPEN_APPID'), request.getenv('WX_OPEN_KEY'), query.code))
  local body = res.body
  if body.errcode then
    return nil, body.errmsg
  end
  local res2 = http.get("https://api.weixin.qq.com/sns/userinfo",
    { query = { access_token = body.access_token, openid = body.openid } })

  -- {
  --   /*7f70dbbc26b0*/
  --   body         : {
  --     /*7f70db9543a0*/
  --     city      : "",
  --     country   : "",
  --     headimgurl: "https://thirdwx.qlogo.cn/mmopen/vi_32/PQdDfb4ibeNWicnqjxRaBTUzficP5ToC5U8iatP1kEeswRhJOHrjhJseAvoe7iaJVWsK8CgPUcIa0ic2gztoLRQPP1HQ/132",
  --     language  : "",
  --     nickname  : "NAN",
  --     openid    : "ou8IF57AUFyrDvhbSKZL8qIvlqx4",
  --     privilege : [
  --       /*7f70db969aa0*/

  --     ],
  --     province  : "",
  --     sex       : 0,
  --     unionid   : "oCtsg5kguGQ8zYCuQG4P-EvC182k",
  --   },
  --   body_reader  : "function: 0x7f70dba00598",
  --   has_body     : true,
  --   headers      : {
  --     /*7f70dbb55598*/
  --     "Content-Length": "329",
  --     "Content-Type"  : "text/plain",
  --     Connection      : "keep-alive",
  --     Date            : "Sat, 11 Mar 2023 01:23:47 GMT",
  --   },
  --   read_body    : "function: 0x7f70dba84ca0",
  --   read_trailers: "function: 0x7f70dba84d58",
  --   reason       : "OK",
  --   status       : 200,
  -- }
  return 'ok'
end

return main
