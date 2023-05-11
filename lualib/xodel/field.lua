local Validator = require "xodel.validator"
local utils = require "xodel.utils"
local lua_array = require "xodel.array"
local env = require "xodel.utils".getenv
local get_payload = require "xodel.alioss".get_payload
local string_format = string.format
local table_concat = table.concat
local table_insert = table.insert
local ipairs = ipairs
local setmetatable = setmetatable
local type = type
local rawset = rawset
local ngx_localtime = ngx.localtime
local class = utils.class

-- local valid_id = utils.valid_id

local TABLE_MAX_ROWS = 1
local CHOICES_ERROR_DISPLAY_COUNT = 30
local DEFAULT_ERROR_MESSAGES = { required = "此项必填", choices = "无效选项" }

-- local PRIMITIVES = {
--   string = true,
--   number = true,
--   boolean = true,
--   table = true,
-- }
local NULL = ngx.null

local NOT_DEFIEND = {}

local function clean_choice(c)
  local v
  if c.value ~= nil then
    v = c.value
  else
    v = c[1]
  end
  assert(v ~= nil, "you must provide a value for a choice")
  local l
  if c.label ~= nil then
    l = c.label
  elseif c[2] ~= nil then
    l = c[2]
  else
    l = v
  end
  return v, l, (c.hint or c[3])
end
local function string_choices_to_array(s)
  local choices = {}
  for _, line in ipairs(utils.split(s, '\n')) do
    line = line:gsub("%s", "")
    if line ~= "" then
      choices[#choices + 1] = line
    end
  end
  return choices
end
local function get_choices(raw_choices)
  if type(raw_choices) == 'string' then
    raw_choices = string_choices_to_array(raw_choices)
  end
  local choices = lua_array {}
  for i, c in ipairs(raw_choices) do
    if type(c) == "string" or type(c) == "number" then
      c = { value = c, label = c }
    elseif type(c) == "table" then
      local value, label, hint = clean_choice(c)
      c = { value = value, label = label, hint = hint }
    else
      error("invalid choice type:" .. type(c))
    end
    choices[#choices + 1] = c
  end
  return choices
end

local function serialize_choice(choice)
  return tostring(choice.value)
end

local function get_choices_error_message(choices)
  local valid_choices = table_concat(utils.map(choices, serialize_choice), "，")
  return string_format("限下列选项：%s", valid_choices)
end

local function get_choices_validator(choices, message)
  if #choices <= CHOICES_ERROR_DISPLAY_COUNT then
    message = string_format("%s，%s", message, get_choices_error_message(choices))
  end
  local is_choice = {}
  for _, c in ipairs(choices) do
    is_choice[c.value] = true
  end
  local function choices_validator(value)
    if not is_choice[value] then
      return nil, message
    else
      return value
    end
  end

  return choices_validator
end

local database_option_names = { 'primary_key', 'null', 'unique', 'index', 'db_type' }
local base_option_names = utils.list(database_option_names, {
  'required', 'label', 'choices', 'choices_url', 'choices_url_method', 'choices_callback', "autocomplete",
  'strict', 'disabled', 'error_messages', 'default', 'hint', 'lazy', 'tag',
  'columns', 'verify_url',
  'post_names', 'code_lifetime', 'tooltip_visible'
})
---@type Field
local basefield = class {
  __is_field_class__ = true,
  NOT_DEFIEND = NOT_DEFIEND,
  required = false,
  option_names = base_option_names,
  __call = function(cls, options)
    local self = cls:new {}
    self:constructor(options)
    self.validators = self:get_validators {}
    return self
  end,
  new = function(cls, self)
    return setmetatable(self or {}, cls)
  end,
  constructor = function(self, options)
    utils.dict_update(self, self:get_options(options))
    if self.db_type == nil then
      self.db_type = self.type
    end
    if self.label == nil then
      self.label = self.name
    end
    if self.null == nil then
      if self.required or self.db_type == 'varchar' or self.db_type == 'text' then
        self.null = false
      else
        self.null = true
      end
    end
    if self.choices then
      if self.strict == nil then
        self.strict = true
      end
      self.choices = get_choices(self.choices)
    end
    self.error_messages = utils.dict(DEFAULT_ERROR_MESSAGES, self.error_messages)
    return self
  end,
  get_options = function(self, options)
    if not options then
      options = self
    end
    local ret = {
      name = options.name,
      type = options.type,
    }
    for _, name in ipairs(self.option_names) do
      if options[name] ~= nil then
        ret[name] = options[name]
      end
    end
    return ret
  end,
  get_validators = function(self, validators)
    if self.required then
      table_insert(validators, 1, Validator.required(self.error_messages.required))
    else
      table_insert(validators, 1, Validator.not_required)
    end
    if self.choices and self.strict then
      table_insert(validators, get_choices_validator(self.choices, self.error_messages.choices))
    end
    return validators
  end,
  json = function(self)
    local json = self:get_options()
    json.error_messages = nil
    if type(json.default) == 'function' then
      json.default = nil
    end
    if not json.tag then
      if json.choices and #json.choices > 0 and not json.autocomplete then
        json.tag = "select"
      else
        json.tag = "input"
      end
    end
    if json.tag == "input" and json.lazy == nil then
      json.lazy = true
    end
    return json
  end,
  widget_attrs = function(self, extra_attrs)
    return utils.dict({ required = self.required, readonly = self.disabled }, extra_attrs)
  end,
  validate = function(self, value, ctx)
    if type(value) == 'function' then
      return value
    end
    local err
    for _, validator in ipairs(self.validators) do
      value, err = validator(value, ctx)
      if value ~= nil then
        if err == nil then
        elseif value == err then
          -- 代表保持原值,跳过此阶段的所有验证
          return value
        else
          return nil, err
        end
      elseif err ~= nil then
        return nil, err
      else
        -- not-required validator, skip the rest validations
        return nil
      end
    end
    return value
  end,
  get_default = function(self, ctx)
    if type(self.default) ~= "function" then
      return self.default
    else
      return self.default(ctx)
    end
  end,
}
local function get_max_choice_length(choices)
  local n = 0
  for _, c in ipairs(choices) do
    local value = c.value
    local n1 = utils.utf8len(value)
    if n1 > n then
      n = n1
    end
  end
  return n
end

local string_option_names = utils.list(basefield.option_names,
  { 'compact', 'trim', 'pattern', "length", "minlength", "maxlength" })
local string = basefield:class {
  type = "string",
  db_type = "varchar",
  compact = true,
  trim = true,
  pattern = nil,
  option_names = string_option_names,
  constructor = function(self, options)
    if not options.choices and not options.length and not options.maxlength then
      error(string_format("field %s must define maxlength or choices or length", options.name))
    end
    basefield.constructor(self, options)
    if self.compact == nil then
      self.compact = true
    end
    if self.default == nil and not self.primary_key and not self.unique then
      self.default = ""
    end
    if self.choices and #self.choices > 0 then
      local n = get_max_choice_length(self.choices)
      assert(n > 0, "invalid string choices(empty choices or zero length value):" .. self.name)
      local m = self.length or self.maxlength
      if not m or n > m then
        self.maxlength = n
      end
    end
    return self
  end,
  get_validators = function(self, validators)
    if self.compact then
      table_insert(validators, 1, Validator.delete_spaces)
    elseif self.trim then
      table_insert(validators, 1, Validator.trim)
    end
    for _, e in ipairs { "pattern", "length", "minlength", "maxlength" } do
      if self[e] then
        table_insert(validators, 1, Validator[e](self[e], self.error_messages[e]))
      end
    end
    table_insert(validators, 1, Validator.string)
    return basefield.get_validators(self, validators)
  end,
  widget_attrs = function(self, extra_attrs)
    local attrs = {
      -- maxlength = self.maxlength,
      minlength = self.minlength
      -- pattern = self.pattern,
    }
    return utils.dict(basefield.widget_attrs(self), attrs, extra_attrs)
  end,
}

local sfzh_option_names = utils.list(string.option_names, {})
local sfzh = string:class {
  type = "sfzh",
  db_type = "varchar",
  option_names = sfzh_option_names,
  constructor = function(self, options)
    string.constructor(self, utils.dict(options, { length = 18 }))
    return self
  end,
  get_validators = function(self, validators)
    table_insert(validators, 1, Validator.sfzh)
    return string.get_validators(self, validators)
  end,
}

local email = string:class {
  type = "email",
  db_type = "varchar",
  constructor = function(self, options)
    string.constructor(self, utils.dict({ maxlength = 255 }, options))
    return self
  end
}

local password = string:class {
  type = "password",
  db_type = "varchar",
  constructor = function(self, options)
    string.constructor(self, utils.dict({ maxlength = 255 }, options))
    return self
  end
}

local year_month = string:class {
  type = "year_month",
  db_type = "varchar",
  constructor = function(self, options)
    string.constructor(self, utils.dict({ maxlength = 7 }, options))
    return self
  end,
  get_validators = function(self, validators)
    table_insert(validators, 1, Validator.year_month)
    return basefield.get_validators(self, validators)
  end,
}

local year = string:class {
  type = "year",
  db_type = "varchar",
  constructor = function(self, options)
    string.constructor(self, utils.dict({ length = 4 }, options))
    return self
  end,
  get_validators = function(self, validators)
    table_insert(validators, 1, Validator.year)
    return basefield.get_validators(self, validators)
  end,
}


local number_validator_names = { "min", "max" }
local function add_min_or_max_validators(self, validators)
  for _, name in ipairs(number_validator_names) do
    if self[name] then
      table_insert(validators, 1, Validator[name](self[name], self.error_messages[name]))
    end
  end
end

local integer_option_names = utils.list(basefield.option_names, { "min", "max", "step", "serial" })
local integer = basefield:class {
  type = "integer",
  db_type = "integer",
  option_names = integer_option_names,
  get_validators = function(self, validators)
    add_min_or_max_validators(self, validators)
    table_insert(validators, 1, Validator.integer)
    return basefield.get_validators(self, validators)
  end,
  json = function(self)
    local json = basefield.json(self)
    if json.primary_key and json.disabled == nil then
      json.disabled = true
    end
    return json
  end,
  prepare_for_db = function(self, value, data)
    if value == "" or value == nil then
      return NULL
    else
      return value
    end
  end
}


local text = basefield:class { type = "text", db_type = "text" }


local float_option_names = utils.list(basefield.option_names, { "min", "max", "step", "precision" })
local float = basefield:class {
  type = "float",
  db_type = "float",
  -- precision = 0,
  option_names = float_option_names,
  get_validators = function(self, validators)
    add_min_or_max_validators(self, validators)
    table_insert(validators, 1, Validator.number)
    return basefield.get_validators(self, validators)
  end,
  prepare_for_db = function(self, value, data)
    if value == "" or value == nil then
      return NULL
    else
      return value
    end
  end,
}


local DEFAULT_BOOLEAN_CHOICES = { { label = '是', value = true }, { label = '否', value = false } }
local boolean_option_names = utils.list(basefield.option_names, { 'cn' })
local boolean = basefield:class {
  type = "boolean",
  db_type = "boolean",
  option_names = boolean_option_names,
  constructor = function(self, options)
    basefield.constructor(self, options)
    if self.choices == nil then
      self.choices = DEFAULT_BOOLEAN_CHOICES
    end
    return self
  end,
  get_validators = function(self, validators)
    if self.cn then
      table_insert(validators, 1, Validator.boolean_cn)
    else
      table_insert(validators, 1, Validator.boolean)
    end
    return basefield.get_validators(self, validators)
  end,
  prepare_for_db = function(self, value, data)
    if value == "" or value == nil then
      return NULL
    else
      return value
    end
  end,
}

local json = basefield:class {
  type = "json",
  db_type = "jsonb",
  json = function(self)
    local json = basefield.json(self)
    json.tag = "textarea"
    return json
  end,
  prepare_for_db = function(self, value, data)
    if value == "" or value == nil then
      return NULL
    else
      return Validator.encode(value)
    end
  end,
}

local function skip_validate_when_string(v)
  if type(v) == "string" then
    return v, v
  else
    return v
  end
end

local function check_array_type(v)
  if type(v) ~= "table" then
    return nil, "array field must be a table"
  else
    return v
  end
end

local function non_empty_array_required(message)
  message = message or "此项必填"
  local function array_validator(v)
    if #v == 0 then
      return nil, message
    else
      return v
    end
  end

  return array_validator
end

local array_option_names = utils.list(basefield.option_names, { 'array_type', })
local array = json:class {
  type = "array",
  db_type = "jsonb",
  option_names = array_option_names,
  constructor = function(self, options)
    if type(options.default) == 'string' then
      options.default = string_choices_to_array(options.default)
    end
    return json.constructor(self, options)
  end,
  get_validators = function(self, validators)
    if self.required then
      table_insert(validators, 1, non_empty_array_required(self.error_messages.required))
    end
    table_insert(validators, 1, check_array_type)
    table_insert(validators, Validator.encode_as_array)
    table_insert(validators, 1, skip_validate_when_string)
    return json.get_validators(self, validators)
  end,
  get_empty_value_to_update = function()
    return utils.array()
  end
}

local function make_empty_array()
  return utils.array()
end

local table_option_names = utils.list(basefield.option_names, { 'model', 'max_rows', 'uploadable' })
local table = array:class {
  type = "table",
  max_rows = TABLE_MAX_ROWS,
  option_names = table_option_names,
  constructor = function(self, options)
    array.constructor(self, options)
    if type(self.model) ~= 'table' or not self.model.__is_model_class__ then
      error("please define model for a table field: " .. self.name)
    end
    if not self.default or self.default == "" then
      self.default = make_empty_array
    end
    if not self.model.table_name then
      self.model.materialize_with_table_name { table_name = self.name, label = self.label }
    end
    return self
  end,
  get_validators = function(self, validators)
    local function validate_by_each_field(rows)
      local err
      for i, row in ipairs(rows) do
        assert(type(row) == "table", "elements of table field must be table")
        row, err = self.model:validate_create(row)
        if row == nil then
          err.index = i
          return nil, err
        end
        rows[i] = row
      end
      return rows
    end

    table_insert(validators, 1, validate_by_each_field)
    return array.get_validators(self, validators)
  end,
  json = function(self)
    local ret = array.json(self)
    local model = { field_names = lua_array {}, fields = {} }
    for _, name in ipairs(self.model.field_names) do
      local field = self.model.fields[name]
      model.field_names:push(name)
      model.fields[name] = field:json()
    end
    ret.model = model
    return ret
  end,
  load = function(self, rows)
    if type(rows) ~= 'table' then
      error('value of table field must be table, not ' .. type(rows))
    end
    for i = 1, #rows do
      rows[i] = self.model:load(rows[i])
    end
    return lua_array(rows)
  end,
}

local datetime_option_names = utils.list(basefield.option_names, {
  'auto_now_add',
  'auto_now',
  'precision',
  'timezone',
  "value_format", -- antdv
  "time_format",  --antdv
})
local datetime = basefield:class {
  type = "datetime",
  db_type = "timestamp",
  precision = 0,
  timezone = true,
  option_names = datetime_option_names,
  constructor = function(self, options)
    basefield.constructor(self, options)
    if self.auto_now_add then
      self.default = ngx_localtime
    end
    return self
  end,
  get_validators = function(self, validators)
    table_insert(validators, 1, Validator.datetime)
    return basefield.get_validators(self, validators)
  end,
  json = function(self)
    local ret = basefield.json(self)
    if ret.disabled == nil and (ret.auto_now or ret.auto_now_add) then
      ret.disabled = true
    end
    return ret
  end,
  prepare_for_db = function(self, value, data)
    if self.auto_now then
      return ngx_localtime()
    elseif value == "" or value == nil then
      return NULL
    else
      return value
    end
  end,
}
local date_option_names = utils.list(basefield.option_names, {
  "value_format", -- antdv
  "time_format",  --antdv
})
local date = basefield:class {
  type = "date",
  db_type = "date",
  option_names = date_option_names,
  get_validators = function(self, validators)
    table_insert(validators, 1, Validator.date)
    return basefield.get_validators(self, validators)
  end,
  prepare_for_db = function(self, value, data)
    if value == "" or value == nil then
      return NULL
    else
      return value
    end
  end,
}

local time_option_names = utils.list(basefield.option_names, { 'precision', 'timezone' })
local time = basefield:class {
  type = "time",
  db_type = "time",
  precision = 0,
  timezone = true,
  option_names = time_option_names,
  get_validators = function(self, validators)
    table_insert(validators, 1, Validator.time)
    return basefield.get_validators(self, validators)
  end,
  prepare_for_db = function(self, value, data)
    if value == "" or value == nil then
      return NULL
    else
      return value
    end
  end,
}


local VALID_FOREIGN_KEY_TYPES = {
  foreignkey = tostring,
  string = tostring,
  sfzh = tostring,
  integer = Validator.integer,
  float = tonumber,
  datetime = Validator.datetime,
  date = Validator.date,
  time = Validator.time
}
-- **默认的外键转换函数为字符串, 外键self功能导致,待完善
local foreignkey_option_names = utils.list(basefield.option_names,
  { 'reference', 'reference_column', 'reference_label_column', 'reference_url', 'realtime',
    'admin_url_name', 'models_url_name', 'keyword_query_name',
    'limit_query_name', 'autocomplete', 'choices_url', 'table_name' })
local foreignkey = basefield:class {
  type = "foreignkey",
  admin_url_name = 'admin',
  models_url_name = 'model',
  convert = tostring,
  option_names = foreignkey_option_names,
  constructor = function(self, options)
    basefield.constructor(self, utils.dict({ db_type = NOT_DEFIEND }, options))
    local fk_model = self.reference
    if fk_model == "self" then
      -- ** 这里跳过? 或者应该在model初始化完成后再自检.todo
      -- if self.db_type == NOT_DEFIEND then
      --   self.db_type = self.type
      -- end
      return self
    end
    assert(type(fk_model) == "table" and fk_model.__is_model_class__,
      string_format("a foreignkey must define a reference model. not %s(type: %s)", fk_model, type(fk_model)))
    local rc = self.reference_column or fk_model.primary_key or "id"
    local fk = fk_model.fields[rc]
    assert(fk, string_format("invalid foreignkey name %s for foreign model %s", rc,
      fk_model.table_name or "[TABLE NAME NOT DEFINED YET]"))
    self.reference_column = rc
    local rlc = self.reference_label_column or rc
    assert(fk_model.fields[rlc], string_format("invalid foreignkey label name %s for foreign model %s", rlc,
      fk_model.table_name or "[TABLE NAME NOT DEFINED YET]"))
    self.reference_label_column = rlc
    self.convert = assert(VALID_FOREIGN_KEY_TYPES[fk.type],
      string_format("invalid foreignkey (name:%s, type:%s)", fk.name, fk.type))
    assert(fk.primary_key or fk.unique, "foreignkey must be a primary key or unique key")
    if self.db_type == NOT_DEFIEND then
      self.db_type = fk.db_type or fk.type
    end
    return self
  end,
  get_validators = function(self, validators)
    local fk_name = self.reference_column
    local function foreignkey_validator(v)
      local err
      if type(v) == "table" then
        v = v[fk_name]
      end
      v, err = self.convert(v)
      if err then
        return nil, "error when converting foreign key:" .. tostring(err)
      end
      return v
    end

    table_insert(validators, 1, foreignkey_validator)
    return basefield.get_validators(self, validators)
  end,
  load = function(self, value)
    local fk_name = self.reference_column
    local fk_model = self.reference
    local function __index(t, key)
      if fk_model[key] then
        -- perform sql only when key is in fields:
        return fk_model[key]
      elseif fk_model.fields[key] then
        local pk = rawget(t, fk_name)
        if not pk then
          return nil
        end
        local res = fk_model:get { [fk_name] = pk }
        if not res then
          return nil
        end
        for k, v in pairs(res) do
          rawset(t, k, v)
        end
        -- become an instance of fk_model
        fk_model:create_record(t)
        return t[key]
      else
        return nil
      end
    end

    return setmetatable({ [fk_name] = value }, { __index = __index })
  end,
  prepare_for_db = function(self, value, data)
    if value == "" or value == nil then
      return NULL
    else
      return value
    end
  end,
  json = function(self)
    local ret = basefield.json(self)
    ret.reference = self.reference.table_name
    -- ret.autocomplete = true
    if ret.realtime == nil then
      ret.realtime = true
    end
    if ret.keyword_query_name == nil then
      ret.keyword_query_name = "keyword"
    end
    if ret.limit_query_name == nil then
      ret.limit_query_name = "limit"
    end
    if ret.choices_url == nil then
      ret.choices_url = string_format([[/%s/%s/%s/fk/%s/%s]],
        ret.admin_url_name,
        ret.models_url_name,
        ret.table_name,
        ret.name,
        ret.reference_label_column)
    end
    return ret
  end,
}

local ALIOSS_BUCKET = env("ALIOSS_BUCKET") or ""
local ALIOSS_REGION = env("ALIOSS_REGION") or ""
local ALIOSS_SIZE = env("ALIOSS_SIZE") or "1M"

local alioss_option_names = utils.list(basefield.option_names, {
  'size', 'policy', 'size_arg', 'times', 'payload',
  'input_type', 'image', 'maxlength', 'width', 'prefix', 'hash',
  'upload_url',
  'payload_url',
  "list_type",   -- antdv
  "max_count",   -- antdv
  "multiple",    -- antdv
  "accept",      -- antdv
  "button_text", -- antdv
})
local alioss = string:class {
  type = "alioss",
  db_type = "varchar",
  option_names = alioss_option_names,
  constructor = function(self, options)
    string.constructor(self, utils.dict({ maxlength = 255 }, options))
    local size = options.size or ALIOSS_SIZE
    self.key_secret = options.key_secret
    self.key_id = options.key_id
    self.size_arg = size
    self.size = utils.byte_size_parser(size)
    self.lifetime = options.lifetime
    self.upload_url = string_format("//%s.%s.aliyuncs.com/", options.bucket or ALIOSS_BUCKET,
      options.region or ALIOSS_REGION)
    return self
  end,
  ---@param options {size:string,lifetime:number, bucket:string,key:string, key_secret?: string,key_id?:string,success_action_status?:number}
  ---@return {policy:string, OSSAccessKeyId:string, signature:string, success_action_status?:number}
  get_payload = function(self, options)
    return get_payload(utils.dict(self, options))
  end,
  get_validators = function(self, validators)
    table_insert(validators, 1, Validator.url)
    return string.get_validators(self, validators)
  end,
  get_options = function(self, options)
    local json = string.get_options(self, options)
    if json.size_arg then
      json.size = json.size_arg
      json.size_arg = nil
    end
    return json
  end,
  json = function(self)
    local ret = string.json(self)
    if ret.input_type == nil then
      ret.input_type = "file"
    end
    return ret
  end,
}

local alioss_image = alioss:class {
  type = "alioss_image"
}

local alioss_list = array:class {
  type = "alioss_list",
  db_type = "jsonb",
  option_names = alioss_option_names,
  constructor = function(self, options)
    array.constructor(self, options)
    alioss.constructor(self, options)
    return self
  end,
  ---@param options {size:string,lifetime:number, bucket:string,key:string, key_secret?: string,key_id?:string,success_action_status?:number}
  ---@return {policy:string, OSSAccessKeyId:string, signature:string, success_action_status?:number}
  get_payload = function(self, options)
    return get_payload(utils.dict(self, options))
  end,
  get_options = function(self, options)
    return utils.dict(array.get_options(self, options), alioss.get_options(self, options),
      { type = 'alioss_list', db_type = "jsonb" })
  end,
  json = function(self)
    return utils.dict(array.json(self), alioss.json(self))
  end,
}

local alioss_image_list = alioss_list:class {
  type = "alioss_image_list",
  db_type = "jsonb",
}

return {
  basefield = basefield,
  string = string,
  sfzh = sfzh,
  email = email,
  password = password,
  text = text,
  integer = integer,
  float = float,
  datetime = datetime,
  date = date,
  year_month = year_month,
  year = year,
  time = time,
  json = json,
  array = array,
  table = table,
  foreignkey = foreignkey,
  boolean = boolean,
  alioss = alioss,
  alioss_image = alioss_image,
  alioss_list = alioss_list,
  alioss_image_list = alioss_image_list,
}
