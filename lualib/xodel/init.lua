-- ngx.log(ngx.ERR, '-----------init xodel----------')
local app = require("xodel.app")
local array = require("xodel.array")
local auth = require("xodel.auth")
local cookie = require("xodel.cookie")
local field = require("xodel.field")
local object = require("xodel.object")
local repr = require("xodel.repr")
local request = require("xodel.request")
local router = require("xodel.router")
local set = require("xodel.set")
local template = require "resty.template"
local utils = require("xodel.utils")
local validator = require("xodel.validator")
local model_class = require("xodel.model")

local function collect_modules(opts)
  local result = opts.result
  local callback = opts.callback
  for _, file in ipairs(utils.files(opts.path)) do
    local path_table = utils.split_path(file)
    local filename = path_table[#path_table] or ''
    local fn, ext = utils.split_filename_extension(filename)
    local module = nil
    local mpath = nil
    if opts.extension == '.lua' and opts.extension == ext then
      path_table[#path_table] = fn
      mpath = path_table:slice(2):join('.')
      module = require(mpath)
    end
    if ext == opts.extension then
      callback(utils.dict(opts, {
        fn = fn,
        ext = ext,
        filename = filename,
        path_table = path_table,
        module = module,
        requied_path = mpath,
        result = result,
      }))
    end
  end
  return result
end

local function collect_model_callback(opts)
  local model = opts.module
  local result = opts.result
  if type(model) == 'function' then
    model = model(opts.fn)
  end
  if model_class:is_model_class(model) then
    if not model.table_name then
      model:materialize_with_table_name { table_name = opts.fn }
    end
    result[model.table_name:lower()] = model
  elseif type(model) == 'table' then
    local model_exists = false
    for table_name, model_value in pairs(model) do
      if model_class:is_model_class(model_value) then
        if not model_value.table_name then
          model_value:materialize_with_table_name { table_name = utils.camel_to_snake(table_name) }
        end
        result[model_value.table_name:lower()] = model_value
        model_exists = true
      end
    end
    if not model_exists then
      error("no model found in: " .. opts.fn)
    end
  else
    error("invalid model type:" .. type(model))
  end
end

local function transform_params_from_file_name(url)
  return url:gsub('%[(%w+)%]', ':%1')
end

local function collect_controller_callback(opts)
  local view = opts.module
  local result = opts.result
  local url = '/' .. opts.path_table:slice(3):join('/')
  url = transform_params_from_file_name(url)
  if utils.callable(view) then
    -- one file one controller, extract url from path
    result:push { path = url, handler = view }
  elseif type(view) == 'table' then
    if app:is_route(view) then
      -- one file one builder, standard url builder
      result:push(app:normalize_route(view))
    else
      for path, builder in pairs(view) do
        if type(path) == 'number' then
          -- grouping routes by array
          assert(app:is_route(builder), "not a valid route builder:" .. repr(builder))
          builder = app:normalize_route(builder)
          local path = builder.path
          local handler = builder.handler
          local method = builder.method
          if builder.path == '' then
            path = url
          else
            assert(path:sub(1, 1) ~= '/', 'grouping routes should not begin with /, but now it is: ' .. path)
            path = url .. '/' .. path
          end
          result:push { path = path, handler = handler, method = method }
        else
          -- grouping routes by hash_table
          assert(utils.callable(builder), "you must define a callable handler")
          assert(type(path) == 'string', "path must be string, but now is:" .. type(path))
          if path == '' then
            path = url
          elseif path:sub(1, 1) ~= '/' then
            path = url .. '/' .. path
          end
          result:push { path = path, handler = builder }
        end
      end
    end
  else
    error(string.format("invalid route type: url(%s) %s (%s)", url, type(view), view))
  end
end

local function collect_page_callback(opts)
  local path_table = opts.path_table
  local result = opts.result
  local layout_path = opts.layout_path
  local template_lsp = template.new({ root = opts.path })
  local context_path_table = path_table:slice(1, -3) + array { 'controllers', opts.fn .. '.lua' }
  local context_file = context_path_table:join('/')
  local lsp_path = '/' .. path_table:slice(3):join('/')
  local lsp_view
  if utils.file_exists(context_file) then
    local require_path = context_path_table:slice(2):join('.'):sub(1, -5)
    local context_handler = require(require_path)
    function lsp_view(req)
      local context, err = context_handler(req)
      if context ~= nil then
        assert(type(context) == 'table', 'context type should be table')
        context.request = req
      elseif err ~= nil then
        context = { request = req, err = err }
      else
        return nil, "some error happened in context_handler"
      end
      return template_lsp.new(lsp_path, layout_path):process(context)
    end
  else
    function lsp_view(req)
      return template_lsp.new(lsp_path, layout_path):process { request = req }
    end
  end
  result:push { path = lsp_path, handler = lsp_view }
end

local function main()
  template.caching(false)

  _G.xodel = {
    app = app,
    array = array,
    auth = auth,
    cookie = cookie,
    field = field,
    object = object,
    repr = repr,
    request = request,
    router = router,
    set = set,
    template = template,
    utils = utils,
    validator = validator,
    model = model_class,
    env = utils.getenv()
  }

  setmetatable(xodel, { __call = function(t, ...) utils.loger(...) end })

  -- function keys(t)
  --   local ret = {}
  --   for k, v in pairs(t) do
  --     ret[#ret+1] = k
  --   end
  --   return table.concat(ret,'|')
  -- end
  -- ngx.log(ngx.ERR, 'load init:', keys(package.loaded))

  local models = collect_modules {
    result = {},
    path = './models',
    extension = '.lua',
    callback = collect_model_callback,
  }

  local controllers = collect_modules {
    result = array {},
    path = './controllers',
    extension = '.lua',
    callback = collect_controller_callback,
  }
  local pages = collect_modules {
    result = array {},
    path = './pages',
    extension = '.lsp',
    callback = collect_page_callback,
    layout_path = '_layout.html',
  }
  local fs_router = router.new(controllers + pages)
  return { router = fs_router, models = models }
end

local function wrap_init_main()
  local ok, app_init = xpcall(main, debug.traceback)
  if not ok then
    local error_on_init_router = router.new {
      {
        path = '/*',
        handler = function()
          return function()
            local hint = string.format("unhandled error during init_by_lua:\n\n%s", app_init)
            if xodel.env.NODE_ENV == 'development' then
              hint = string.format("%s\n\nenvironment:\n\n%s", hint, repr(xodel.env))
            end
            ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
            ngx.header.content_type = 'text/plain; charset=utf-8'
            ngx.print(hint)
          end
        end
      }
    }
    ngx.log(ngx.ERR, "app init failed: " .. app_init)
    return { router = error_on_init_router, models = {} }
  else
    return app_init
  end
end

return wrap_init_main
