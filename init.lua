-- ngx.log(ngx.ERR, '-----------init app----------')
local xodel_init = require("xodel.init")
local xodel_app = require "xodel.app"
local ngx_var = ngx.var
local cjson = require("cjson.safe")
cjson.encode_empty_table_as_object(false)
local init = xodel_init()
local app = xodel_app:new { router = init.router, models = init.models }

-- require("xodel.dict")
local function dispatch()
  return app:dispatch(ngx_var.document_uri, ngx_var.request_method)
end

-- require("resty.acme.autossl").init({
--   -- setting the following to true
--   -- implies that you read and accepted https://letsencrypt.org/repository/
--   tos_accepted = true,
--   -- uncomment following for first time setup
--   staging = true,
--   -- uncomment following to enable RSA + ECC double cert
--   -- domain_key_types = { 'rsa', 'ecc' },
--   -- uncomment following to enable tls-alpn-01 challenge
--   -- enabled_challenge_handlers = { 'http-01', 'tls-alpn-01' },
--   account_key_path = "conf/account.key",
--   account_email = "280145668@qq.com",
--   domain_whitelist = { "jaqn.jahykj.com" },
-- })

return dispatch
