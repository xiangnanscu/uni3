local ngx = ngx
local var = ngx.var

local function log_by_lua()
  if ngx.ctx.error_message then
    local data = {
      message = ngx.ctx.error_message,
      status = tostring(ngx.ctx.error_status),
      url = var.document_uri,
      remote_addr = var.remote_addr,
      request_method = var.request_method,
      request_uri = var.request_uri,
      bytes_sent = var.bytes_sent,
      http_user_agent = var.http_user_agent,
      http_referer = var.http_referer,
      request_time = var.request_time,
    }
    ngx.timer.at(0, function()
      local ErrorLog = require("models.models").ErrorLog
      local ok, res = pcall(function() ErrorLog:create(data) end)
      if not ok then xodel(res) end
    end)
  end
end

return {
  log_by_lua = log_by_lua
}
