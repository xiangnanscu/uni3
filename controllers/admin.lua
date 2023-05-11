local Object = require("xodel.object")
local models = require("models.models")
local utils = require("xodel.utils")

local models_json_map = {}
local models_map = {}
for name, model in pairs(models) do
  local json = model:to_camel_json()
  models_json_map[name] = json
  models_json_map[utils.camel_to_snake(name)] = json
  models_map[name] = model
  models_map[utils.camel_to_snake(name)] = model
end

local sorted_model_list = Object(models):values():filter(function(model)
  return not model.admin.hide
end):map(function(model)
  return { name = model.table_name, label = model.label }
end):sort(function(a, b)
  return a.name < b.name
end)

local function set_admin_model(controller)
  local function wrapped_admin_controller(request)
    if not request.user or request.user.permission < 1 then
      return nil, "permission not allowed", 403
    end
    local model_name = request.params.model_name
    local model = models_map[model_name]
    if not model then
      return nil, "invalid model name: " .. model_name
    end
    request.model = model
    return controller(request)
  end
  return wrapped_admin_controller
end

local function get_model(request)
  local query = request.get_uri_args()
  local model = models_json_map[request.params.model_name]
  if not model then
    return nil, "invalid model"
  end
  local key = query.key
  if key then
    return utils.chaining_operator(model, key)
  else
    return model
  end
end

local function model_list(request)
  return sorted_model_list
end
local function admin_list(request)
  local query = request.get_uri_args()
  local pagesize = tonumber(query.pagesize or 0)
  local page = tonumber(query.page or 1)
  local names = request.model.admin.list_names or request.model.names
  local list_condition = utils.get_list_search_condition(request.get_post_data())
  local admin_records = request.model:where(list_condition):select('id'):select(names):order('id DESC')
  if pagesize ~= 0 then
    admin_records:limit(pagesize):offset((page - 1) * pagesize)
  end
  local total = request.model:count(list_condition)
  return { records = admin_records:exec(), total = total }
end

local function admin_detail(request)
  local id = request.params.id
  local names = request.model.admin.detail_names or request.model.names
  local ins = request.model:select(names):get { id = id }
  return ins
end

local function admin_get(request)
  local data = request.get_post_data()
  local names = request.model.admin.detail_names or request.model.names
  local ins = request.model:select(names):get(data)
  return ins
end

local function admin_create(request)
  local data = request:get_post_data()
  return request.model:save_create(data)
end

local function admin_update(request)
  local id = request.params.id
  local data = request:get_post_data()
  return request.model:update(data):where { id = id }:execr()
end

local function admin_delete(request)
  local id = request.params.id
  return request.model:delete { id = id }:execr()
end

local function admin_download(request)
  return request.model:order('id DESC'):where {}:execr()
end

local function admin_merge(request)
  local query = request.get_uri_args()
  local rows = request.get_post_data()
  local admin = request.model.admin
  return request.model:merge(rows, query.key or admin.merge_key, query.columns or admin.merge_columns)
end

local function admin_choices(request)
  local query = request.get_uri_args()
  local s_value = request.format("%s as value", query.value)
  local s_label = request.format("%s as label", query.label or query.value)
  return request.model:select(s_value, s_label):execr()
end

local function admin_foreignkey_list(request)
  local fk_name = request.params.fk_name
  local fk = request.model.fields[fk_name]
  if not fk then
    return nil,
        request.format("invalid foreignkey_name %s for model %s", fk_name, request.model.table_name)
  end
  if not fk.reference then
    return nil, request.format("%s is not a foreignkey_name for model %s", fk_name, request.model.table_name)
  end
  return fk.reference:order('id DESC'):select(
        fk.reference_column .. ' as value',
        fk.reference_label_column .. ' as label')
      :execr()
end

local login_names = { "id", "nickname", "username", "avatar", "openid", "permission", "password" }
local function admin_login(request)
  local data = request.get_post_data()
  local user = models.Usr:select(login_names):try_get { username = data.username }
  if not user then
    return { code = 422, msg = '用户不存在', name = 'username' }
  end
  if user.password == data.password then
    request.session.user = user
    user.password = nil
    return { code = 200, user = user }
  else
    return { code = 422, msg = "密码不正确", name = 'password' }
  end
end

return {
  { "model_list",                                   model_list },
  { "login",                                        admin_login },
  { "model/:model_name",                            set_admin_model(get_model),             "get" },
  { "model/:model_name/list",                       set_admin_model(admin_list),            "post" },
  { "model/:model_name/detail/#id",                 set_admin_model(admin_detail),          "get" },
  { "model/:model_name/get",                        set_admin_model(admin_get),             "post" },
  { "model/:model_name/create",                     set_admin_model(admin_create),          "post" },
  { "model/:model_name/update/#id",                 set_admin_model(admin_update),          "post" },
  { "model/:model_name/delete/#id",                 set_admin_model(admin_delete),          "post" },
  { "model/:model_name/download",                   set_admin_model(admin_download),        "get" },
  { "model/:model_name/merge",                      set_admin_model(admin_merge),           "post" },
  { "model/:model_name/choices",                    set_admin_model(admin_choices),         "post" },
  { "model/:model_name/fk/:fk_name/:fk_label_name", set_admin_model(admin_foreignkey_list), "post" },
}
