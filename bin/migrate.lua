local lfs = require "syscall.lfs"
local utils = require "xodel.utils"
local Query = require "xodel.query"
local Array = require "xodel.array"
local Model = require "xodel.model"
local migrate = require "xodel.migrate"
local xodel_init = require("xodel.init")

xodel_init()
local match = ngx.re.match
local format = string.format
local getenv = utils.getenv

local MIGRATEFOLDER = 'migrate'
local WORKING_APP;
local APPEND_MODE = false
local MIGRATE_MESSAGE = ""

local make_model_for_compare = migrate.make_model_for_compare
local compare_models = migrate.compare_models
local get_table_defination = migrate.get_table_defination
local split_path = utils.split_path

local app_query = Query {
  getenv = getenv,
  HOST = getenv "PGHOST" or "127.0.0.1",
  PORT = getenv "PGPORT" or 5432,
  DATABASE = getenv "PGDATABASE" or "postgres",
  USER = getenv "PGUSER" or "postgres",
  PASSWORD = getenv "PGPASSWORD" or "postgres",
}

local function migrate_print(...)
  print("***xodel migreate*** ", ...)
end

local function loger(...)
  migrate_print(utils.repr(...))
end

-- local Migrate = utils.class {
--   app = nil,
--   is_append = false,
--   message = "",
--   create_migrate = function()
--   end
-- }


local function match_migrate_log_name(fn)
  return match(fn, [[\d{4}-\d\d-\d\d_\d\d:\d\d:\d\d_\w*_(\d+)$]])
end

local function slug(s)
  return (s:gsub("[^%w]", "_"))
end

local function get_migrate_folder(app_name)
  return app_name and format("%s/%s", app_name, MIGRATEFOLDER) or MIGRATEFOLDER
end

local function get_migrate_logs_folder(app_name)
  return get_migrate_folder(app_name) .. "/logs"
end

local function get_migrate_number(fn)
  return tonumber(match_migrate_log_name(fn)[1])
end

local function ensure_migrate_log_folder(app_name)
  local migrate_folder = get_migrate_folder(app_name)
  if not utils.dir_exists(migrate_folder) then
    lfs.mkdir(migrate_folder)
  end
  local logs_folder = get_migrate_logs_folder(app_name)
  assert(utils.mkdirs(logs_folder))
  local mfolders = Array(utils.folders(logs_folder)):map(utils.get_filename):filter(match_migrate_log_name):sort()
  local current_number = #mfolders == 0 and 0 or get_migrate_number(mfolders[#mfolders])
  local app_migrate_log_folder = format("%s/%s_%s_%s",
    logs_folder,
    os.date("%Y-%m-%d_%H:%M:%S"),
    slug(MIGRATE_MESSAGE),
    current_number + 1)
  if not utils.dir_exists(app_migrate_log_folder) then
    assert(lfs.mkdir(app_migrate_log_folder))
  end
  return app_migrate_log_folder
end

local function make_models_snap(app_name)
  local app_migrate_log_folder = ensure_migrate_log_folder(app_name)
  local model_folder = format("%s/models", app_name or ".")
  local function write_model_to_file(model, table_name)
    local model_json = make_model_for_compare(model)
    assert(utils.write_json(format("%s/%s.json", app_migrate_log_folder, model.table_name), model_json))
  end

  local function write_model()
    for _, model_path in ipairs(utils.files(model_folder)) do
      if model_path:sub(-4) == ".lua" then
        local pt = split_path(model_path)
        local model_name = pt[#pt]:sub(1, -5)
        local require_path = format("%smodels.%s", app_name and app_name .. '.' or '', model_name)
        local model = require(require_path)
        if Model:is_model_class(model) then
          write_model_to_file(model, model_name)
        elseif type(model) == 'table' then
          local model_exists = false
          for camel_model_name, model_value in pairs(model) do
            assert(model_value.table_name, format("table_name of %s is not set yet", camel_model_name))
            if Model:is_model_class(model_value) then
              write_model_to_file(model_value, camel_model_name)
              model_exists = true
            end
          end
          if not model_exists then
            error("no model found in: " .. model_path)
          end
        else
          error("invalid model type:" .. type(model))
        end
      end
    end
  end

  local ok, err = pcall(write_model)
  if not ok then
    migrate_print("make model snap failed: " .. err)
    utils.exec("rm -rf %s", app_migrate_log_folder)
    error(err)
  end
end

local function sort_model(a, b)
  for i, f in pairs(b.fields) do
    if f.reference and f.reference.table_name == a.table_name then
      return true
    end
  end
  return false
end

local function get_models_from_json_path(path, is_map)
  local models = Array {}
  local json_files = Array(utils.files(path, 0)):filter(function(f)
    return f:sub(-5) == '.json'
  end)
  for i, model_json_path in ipairs(json_files) do
    local model = assert(utils.load_json(model_json_path))
    if is_map then
      models[model.table_name] = model
    else
      models[i] = model
    end
  end
  if is_map then
    return models
  else
    return models:sort(sort_model)
  end
end

local function sort_log_folder(a, b)
  local diff = get_migrate_number(a) - get_migrate_number(b)
  if diff == 0 then
    return false
  elseif diff < 0 then
    return false
  else
    return true
  end
end

local function diff_latest_models_to_sql(app_name)
  -- 比较最新的两个log文件夹, 得出diff.sql, 写入文件
  local final_tokens = {}
  local logs_folder = get_migrate_logs_folder(app_name)
  local logs = Array(utils.folders(logs_folder)):sort(sort_log_folder)
  if #logs == 0 then
    return
  end
  if #logs == 1 then
    local new_models = get_models_from_json_path(logs[1])
    for i, new_model in ipairs(new_models) do
      local token = get_table_defination(new_model)
      table.insert(final_tokens, token)
    end
  else
    local new_models = get_models_from_json_path(logs[1])
    local old_models_map = get_models_from_json_path(logs[2], true)
    for _, new_model in pairs(new_models) do
      local table_name = new_model.table_name
      if not old_models_map[table_name] then
        -- create table
        local token = get_table_defination(new_model)
        table.insert(final_tokens, token)
      else
        local tokens = compare_models(old_models_map[table_name], new_model)
        utils.list_extend(final_tokens, tokens)
      end
    end
  end
  if #final_tokens == 0 then
    migrate_print("nothing changes...")
    return
  end
  -- migrate_print("migrations:")
  -- for i, token in ipairs(final_tokens) do
  --   print(token)
  -- end
  local sql_token = table.concat(final_tokens, ';\n') .. ';'
  io.open(format('%s/_diff.sql', logs[1]), "w"):write(sql_token):close()
  local mfn = format('%s/diff.sql', utils.get_dir(logs_folder))
  if APPEND_MODE then
    local current_sql
    local file, err = io.open(mfn, "r")
    if file ~= nil then
      current_sql, err = file:read("*a")
      if current_sql == nil then
        migrate_print("fail to read file content:", err)
        return
      end
    end
    local prefix
    if current_sql == '' or current_sql == nil then
      prefix = ''
    else
      prefix = '\n'
    end
    io.open(mfn, "a"):write(prefix .. sql_token):close()
  else
    io.open(mfn, "w"):write(sql_token):close()
  end
end

local function get_latest_migrate_log(app_name)
  local logs_folder = get_migrate_logs_folder(app_name)
  local logs = Array(utils.folders(logs_folder)):sort(function(a, b)
    return a > b
  end)
  if #logs == 0 then
    migrate_print("no logs..")
    return
  end
  return logs[1]
end

local function get_latest_migrate_sql(app_name)
  local log_folder = get_latest_migrate_log(app_name)
  if not log_folder then
    return
  end
  local log_path = format('%s/_diff.sql', log_folder)
  if not utils.file_exists(log_path) then
    migrate_print("sql file not existed (maybe no diff)")
    return
  end
  local file = assert(io.open(log_path))
  local sql_statement = assert(file:read("a*"))
  return sql_statement
end

local function commit_latest_migrate_sql(app_name)
  local sql_statement = get_latest_migrate_sql(app_name)
  if not sql_statement then
    migrate_print("no latest sql to execute")
    return
  end
  migrate_print("commit latest migrations below")
  print(sql_statement)
  local res, err = app_query(sql_statement)
  if not res then
    migrate_print("failed to exec sql: " .. tostring(err))
  else
    migrate_print('  successfully migrate!')
  end
end

local function clear_sql_file(app_name)
  local fn = format('%s/diff.sql', get_migrate_folder(app_name))
  io.open(fn, "w"):write(""):close()
  migrate_print("cleared: " .. fn)
end

local function get_migrate_sql(app_name)
  local app_migrate_folder = get_migrate_folder(app_name)
  local file = assert(io.open(format('%s/diff.sql', app_migrate_folder)))
  local sql_statement = assert(file:read("a*"))
  if #sql_statement < 1 then
    return
  end
  return sql_statement
end

local function commit_migrate_sql(app_name)
  local sql_statement = get_migrate_sql(app_name)
  if not sql_statement then
    migrate_print("no sql to execute")
    return
  end
  migrate_print("commit all migrations below:")
  print(sql_statement)
  local res, err = app_query(sql_statement)
  if not res then
    migrate_print("failed to exec sql: " .. tostring(err))
  else
    migrate_print('successfully migrate!')
  end
end

local function prefix(str)
  return function(e)
    return e:sub(1, #str) == str
  end
end

local cmd_map = {
  {
    flag = "-rollback",
    task = function()
      local path = get_latest_migrate_log(WORKING_APP)
      migrate_print("delete foler: " .. path)
      utils.exec("rm -rf %s", path)
    end
  },
  {
    flag = "-remove",
    task = function()
      local path = get_migrate_folder(WORKING_APP)
      migrate_print("delete foler: " .. path)
      utils.exec("rm -rf %s", path)
    end
  },
  {
    flag = "-clear",
    task = function()
      clear_sql_file(WORKING_APP)
    end
  },
  {
    flag = "-append",
    task = function()
      APPEND_MODE = true
    end
  },
  {
    flag = "-message",
    task = function()

    end
  },
  {
    flag = "-snap",
    task = function()
      make_models_snap(WORKING_APP)
    end
  },
  {
    flag = "-diff",
    task = function()
      diff_latest_models_to_sql(WORKING_APP)
    end
  },
  {
    flag = "-commit",
    task = function()
      commit_migrate_sql(WORKING_APP)
    end
  },
  {
    flag = "-commit-latest",
    task = function()
      commit_latest_migrate_sql(WORKING_APP)
    end
  },
  {
    flag = "-show",
    task = function()
      migrate_print("show migrations for app" .. (WORKING_APP or " main"))
      local statement = get_migrate_sql(WORKING_APP)
      if statement then
        migrate_print("all migrations below")
        print(statement)
      end
      statement = get_latest_migrate_sql(WORKING_APP)
      if statement then
        migrate_print("latest migration below")
        print(statement)
      end
    end
  },
}


if select('#', ...) == 0 then
  if #arg == 0 then
    migrate_print("no args provided for migrate, exit...")
    return
  end
  local args = Array(arg)
  local app_arg = args:find(prefix('-app='))
  if app_arg then
    WORKING_APP = app_arg:sub(#'-app=' + 1)
  end
  local msg_arg = args:find(prefix('-message='))
  if msg_arg then
    MIGRATE_MESSAGE = msg_arg:sub(#'-message=' + 1)
  end
  for _, e in ipairs(cmd_map) do
    if args:find(e.flag) ~= nil then
      e.task()
    end
  end
end
