local Model = require "xodel.model"

local ErrorLog = Model {
  table_name = 'error_log',
  label = "错误日志",
  admin = {
    list_names = { 'ctime', 'url', 'message',
      --  'remote_addr', 'request_method', 'status', 'request_time',
    },
  },
  fields = {
    { name = 'message',         label = "错误信息",    type = 'text' },
    { name = 'status', },
    { name = 'remote_addr',     label = "IP", },
    { name = 'request_method',  label = "method", },
    { name = 'url', },
    { name = 'request_uri', },
    { name = 'bytes_sent',      label = "响应包大小", type = "integer", default = 0 },
    { name = 'http_referer',    label = "请求来源",    maxlength = 1024 },
    { name = 'http_user_agent', label = "浏览器",       maxlength = 1024 },
    { name = 'request_time',    label = "请求时间",    type = "float",   default = 0 },
  }
}

return {
  ErrorLog = ErrorLog
}
