-- https://www.postgreSql.org/docs/current/sql-select.html
-- https://www.postgreSql.org/docs/current/sql-insert.html
-- https://www.postgreSql.org/docs/current/sql-update.html
-- https://www.postgreSql.org/docs/current/sql-delete.html
local Array = require "xodel.array"
local Object = require "xodel.object"
local Field = require "xodel.field"
local Sql = require "xodel.sql"
local Query = require "xodel.query"
local getenv = require "xodel.utils".getenv
local clone = require "table.clone"
local utils = require "xodel.utils"
local setmetatable = setmetatable
local ipairs = ipairs
local tostring = tostring
local type = type
local next = next
local pairs = pairs
local assert = assert
local error = error
local string_format = string.format
local table_concat = table.concat
local table_insert = table.insert
local ngx_localtime = ngx.localtime
local match = ngx.re.match
local table_new = table.new
local NULL = Sql.NULL

local default_query = Query {
  getenv = getenv,
  HOST = getenv "PGHOST" or "127.0.0.1",
  PORT = getenv "PGPORT" or 5432,
  DATABASE = getenv "PGDATABASE" or "postgres",
  USER = getenv "PGUSER" or "postgres",
  PASSWORD = getenv "PGPASSWORD" or "postgres",
}
local DEFAULT_STRING_MAXLENGTH = 256
local FOREIGN_KEY = 2
local NON_FOREIGN_KEY = 3
local END = 4
local IS_PG_KEYWORDS = {
  ALL = true,
  ANALYSE = true,
  ANALYZE = true,
  AND = true,
  ANY = true,
  ARRAY = true,
  AS = true,
  ASC = true,
  ASYMMETRIC = true,
  AUTHORIZATION = true,
  BINARY = true,
  BOTH = true,
  CASE = true,
  CAST = true,
  CHECK = true,
  COLLATE = true,
  COLLATION = true,
  COLUMN = true,
  CONCURRENTLY = true,
  CONSTRAINT = true,
  CREATE = true,
  CROSS = true,
  CURRENT_CATALOG = true,
  CURRENT_DATE = true,
  CURRENT_ROLE = true,
  CURRENT_SCHEMA = true,
  CURRENT_TIME = true,
  CURRENT_TIMESTAMP = true,
  CURRENT_USER = true,
  DEFAULT = true,
  DEFERRABLE = true,
  DESC = true,
  DISTINCT = true,
  DO = true,
  ELSE = true,
  END = true,
  EXCEPT = true,
  FALSE = true,
  FETCH = true,
  FOR = true,
  FOREIGN = true,
  FREEZE = true,
  FROM = true,
  FULL = true,
  GRANT = true,
  GROUP = true,
  HAVING = true,
  ILIKE = true,
  IN = true,
  INITIALLY = true,
  INNER = true,
  INTERSECT = true,
  INTO = true,
  IS = true,
  ISNULL = true,
  JOIN = true,
  LATERAL = true,
  LEADING = true,
  LEFT = true,
  LIKE = true,
  LIMIT = true,
  LOCALTIME = true,
  LOCALTIMESTAMP = true,
  NATURAL = true,
  NOT = true,
  NOTNULL = true,
  NULL = true,
  OFFSET = true,
  ON = true,
  ONLY = true,
  OR = true,
  ORDER = true,
  OUTER = true,
  OVERLAPS = true,
  PLACING = true,
  PRIMARY = true,
  REFERENCES = true,
  RETURNING = true,
  RIGHT = true,
  SELECT = true,
  SESSION_USER = true,
  SIMILAR = true,
  SOME = true,
  SYMMETRIC = true,
  TABLE = true,
  TABLESAMPLE = true,
  THEN = true,
  TO = true,
  TRAILING = true,
  TRUE = true,
  UNION = true,
  UNIQUE = true,
  USER = true,
  USING = true,
  VARIADIC = true,
  VERBOSE = true,
  WHEN = true,
  WHERE = true,
  WINDOW = true,
  WITH = true,
}
local NON_MERGE_NAMES = {
  sql = true,
  fields = true,
  field_names = true,
  extends = true,
  mixins = true,
  __index = true,
  admin = false
}

local base_model = {
  abstract = true,
  field_names = Array { "id", "ctime", "utime" },
  fields = {
    id = { type = "integer", primary_key = true, serial = true },
    ctime = { label = "创建时间", type = "datetime", auto_now_add = true },
    utime = { label = "更新时间", type = "datetime", auto_now = true }
  }
}

local function disable_setting_model_attrs(cls, key, value)
  error(string_format("modify model class '%s' is not allowed (key: %s, value: %s)", cls.table_name, key, value))
end

local function dict(t1, t2)
  local res = clone(t1)
  if t2 then
    for key, value in pairs(t2) do
      res[key] = value
    end
  end
  return res
end

local function check_reserved(name)
  assert(type(name) == "string", string_format("name must by string, not %s (%s)", type(name), name))
  assert(not name:find("__", 1, true), "don't use __ in a field name")
  assert(not IS_PG_KEYWORDS[name:upper()], string_format("%s is a postgresql reserved word", name))
end

local function normalize_array_and_hash_fields(fields)
  assert(type(fields) == "table", "you must provide fields for a model")
  local aligned_fields = {}
  local field_names = Array {}
  for name, field in pairs(fields) do
    if type(name) == 'number' then
      assert(field.name, "you must define name for a field when using array fields")
      aligned_fields[field.name] = field
      field_names:push(field.name)
    else
      aligned_fields[name] = field
      field_names:push(name)
    end
  end
  return aligned_fields, field_names
end

local function normalize_field_names(field_names)
  assert(type(field_names) == "table", "you must provide field_names for a model")
  for _, name in ipairs(field_names) do
    assert(type(name) == 'string', "element of field_names must be string")
  end
  return Array(field_names)
end

local function is_field_class(t)
  return type(t) == 'table' and getmetatable(t) and getmetatable(t).__is_field_class__
end

local function get_foreign_object(attrs, prefix)
  -- when in : attrs = {id=1, buyer__name='tom', buyer__id=2}, prefix = 'buyer__'
  -- when out: attrs = {id=1}, fk_instance = {name='tom', id=2}
  local fk = {}
  local n = #prefix
  for k, v in pairs(attrs) do
    if k:sub(1, n) == prefix then
      fk[k:sub(n + 1)] = v
      attrs[k] = nil
    end
  end
  return fk
end

---@param json {[string]:any}
---@param kwargs? {[string]:any}
---@return Field
local function make_field_from_json(json, kwargs)
  local options = dict(json, kwargs)
  if not options.type then
    if options.reference then
      options.type = "foreignkey"
    elseif options.model then
      options.type = "table"
    else
      options.type = "string"
    end
  end
  if (options.type == "string" or options.type == "alioss") and not options.maxlength then
    options.maxlength = DEFAULT_STRING_MAXLENGTH
  end
  ---@type Field
  local fcls = Field[options.type]
  if not fcls then
    error("invalid field type:" .. tostring(options.type))
  end
  return fcls(options)
end


---@param row any
---@return boolean
local function is_sql_instance(row)
  local meta = getmetatable(row)
  return meta and meta.__SQL_BUILDER__
end

local as_token = Sql.as_token
local as_literal = Sql.as_literal
local as_literal_without_brackets = Sql.as_literal_without_brackets


---@class Sql
---@field model Xodel
---@field _skip_validate? boolean
---@field _compact? boolean
---@field _commit? boolean
---@field _raw? boolean
---@field _join_keys? table
---@field _load_fk? table
local ModelSql = utils.class(utils.dict({}, Sql), { __call = Sql.__call })

--- {{id=1}, {id=2}, {id=3}} => columns: {'id'}  keys: {{1},{2},{3}}
--- each row of keys must be the same struct, so get columns from first row
---@param self Sql
---@param keys Record[]
---@param columns? string[]
---@return Sql
function ModelSql._base_get_multiple(self, keys, columns)
  if #keys == 0 then
    error("empty keys passed to get_multiple")
  end
  columns = columns or utils.get_keys(keys[1])
  keys, columns = self:_get_cte_values_literal(keys, columns, false)
  local join_cond = self:_get_join_conditions(columns, "V", self._as or self.table_name)
  local cte_name = string_format("V(%s)", table_concat(columns, ", "))
  local cte_values = string_format("(VALUES %s)", as_token(keys))
  return self:with(cte_name, cte_values):right_join("V", join_cond)
end

---@param self Sql
---@param rows Record[]
---@param columns? string[]
---@param no_check? boolean
---@return string[], string[]
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql._get_cte_values_literal(self, rows, columns, no_check)
  columns = columns or utils.get_keys(rows)
  rows = self:_rows_to_array(rows, columns)
  local first_row = rows[1]
  for i, col in ipairs(columns) do
    local field = self:_find_field_model(col)
    if field then
      first_row[i] = string_format("%s::%s", as_literal(first_row[i]), field.db_type)
    elseif no_check then
      first_row[i] = as_literal(first_row[i])
    else
      error("invalid field name for _get_cte_values_literal: " .. col)
    end
  end
  ---@type string[]
  local res = {}
  res[1] = '(' .. as_token(first_row) .. ')'
  for i = 2, #rows, 1 do
    res[i] = as_literal(rows[i])
  end
  return res, columns
end

---@param self Sql
---@param rows Record[]
---@param columns string[]
---@return DBValue[][]
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql._rows_to_array(self, rows, columns)
  local c = #columns
  local n = #rows
  local res = table_new(n, 0)
  local fields = self.model.fields
  for i = 1, n do
    res[i] = table_new(c, 0)
  end
  for i, col in ipairs(columns) do
    for j = 1, n do
      local v = rows[j][col]
      if v ~= nil and v ~= '' then
        res[j][i] = v
      elseif fields[col] then
        local default = fields[col].default
        if default ~= nil then
          res[j][i] = fields[col]:get_default(rows[j])
        else
          res[j][i] = NULL
        end
      else
        res[j][i] = NULL
      end
    end
  end
  return res
end

---@param self Sql
---@param join_args table
---@param join_type? JOIN_TYPE
---@return table, boolean
function ModelSql._register_join_model(self, join_args, join_type)
  join_type = join_type or join_args.join_type or "INNER"
  local find = true
  -- 有可能出现self.model.table_name和self.table_name不一样的情况,例如get_or_create
  local model, table_name
  if join_args.model then
    model = join_args.model
    table_name = model.table_name
  else
    model = self.model
    table_name = self.table_name
  end
  local column = join_args.column
  local f = assert(model.fields[column], string_format("invalid name %s for model %s", column, table_name))
  local fk_model = join_args.fk_model or f and f.reference
  local fk_column = join_args.fk_column or f and f.reference_column
  local join_key
  if join_args.join_key == nil then
    if self.table_name == table_name then
      -- 如果是本体model连接, 则join_key的定义方式与_get_where_key和load_fk一致,避免生成重复的join
      -- 同一个列,可能和不同的表join多次, 因此要加上外键表名, 避免自动判断错误
      join_key = column .. "__" .. fk_model.table_name
    else
      join_key = string_format("%s__%s__%s__%s__%s", join_type, table_name, column, fk_model.table_name,
        fk_column)
    end
  else
    join_key = join_args.join_key
  end
  if not self._join_keys then
    self._join_keys = {}
  end
  local join_obj = self._join_keys[join_key]
  if not join_obj then
    find = false
    join_obj = {
      join_type = join_type,
      model = model,
      column = column,
      alias = join_args.alias or table_name,
      fk_model = fk_model,
      fk_column = fk_column,
      fk_alias = join_args.fk_alias or ('T' .. self:_get_join_number())
    }
    local join_table = string_format("%s %s", fk_model.table_name, join_obj.fk_alias)
    local join_cond = string_format("%s.%s = %s.%s", join_obj.alias, join_obj.column, join_obj.fk_alias,
      join_obj.fk_column)
    self:_handle_join(join_type, join_table, join_cond)
    self._join_keys[join_key] = join_obj
  end
  return join_obj, find
end

---@param self Sql
---@param col string
---@return Field?, Xodel?,string?
function ModelSql._find_field_model(self, col)
  local field = self.model.fields[col]
  if field then
    return field, self.model, self._as or self.table_name
  end
  if not self._join_keys then
    return
  end
  for _, join_obj in pairs(self._join_keys) do
    local fk_field = join_obj.fk_model.fields[col]
    if join_obj.model.table_name == self.table_name and fk_field then
      return fk_field, join_obj.fk_model, (join_obj.fk_alias or join_obj.fk_model.table_name)
    end
  end
end

---@param self Sql
---@param key string
---@return string, string
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql._get_where_key(self, key)
  local a, b = key:find("__", 1, true)
  if not a then
    return self:_get_column(key) --[[@as string]], "eq"
  end
  local e = key:sub(1, a - 1)
  local field, model, prefix = self:_find_field_model(e)
  if not field or not model then
    error(string_format("%s is not a valid field name for %s", e, self.table_name))
  end
  local i, state, fk_model, rc, join_key
  local op = "eq"
  local field_name = e
  if field.reference then
    fk_model = field.reference
    rc = field.reference_column
    state = FOREIGN_KEY
  else
    state = NON_FOREIGN_KEY
  end
  while true do
    i = b + 1
    a, b = key:find("__", i, true)
    if not a then
      e = key:sub(i)
    else
      e = key:sub(i, a - 1)
    end
    if state == NON_FOREIGN_KEY then
      -- foo__lt, foo__gt, etc
      op = e
      state = END
    elseif state == FOREIGN_KEY then
      local field_of_fk = fk_model.fields[e]
      if field_of_fk then
        -- profile{usr__sfzh}, fk_model: usr, rc: id
        if not join_key then
          join_key = field_name .. "__" .. fk_model.table_name
        else
          join_key = join_key .. "__" .. field_name
        end
        local join_obj = self:_register_join_model {
          join_key = join_key,
          model = model,
          column = field_name,
          -- alias = prefix or model.table_name, -- prefix永不为空, 这句不知怎么来的
          alias = assert(prefix, "prefix in _get_where_key should never be falsy"),
          fk_model = fk_model,
          fk_column = rc
        }
        prefix = join_obj.fk_alias
        if field_of_fk.reference then
          -- -- profile{usr__addr__like}, fk_model: usr, rc: id
          model = fk_model --[[@as Xodel]]
          fk_model = field_of_fk.reference
          rc = field_of_fk.reference_column
        else
          -- fk1__name
          state = NON_FOREIGN_KEY
        end
        field_name = e
      else
        -- fk__eq, fk__lt, etc
        op = e
        state = END
      end
    else
      error(string_format("invalid cond table key parsing state %s with token %s", state, e))
    end
    if not a then
      break
    end
  end
  return prefix .. "." .. field_name, op
end

---@param self Sql
---@param key string
---@return string
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql._get_column(self, key)
  if self.model.fields[key] then
    return self._as and (self._as .. '.' .. key) or self.model.name_cache[key]
  end
  if not self._join_keys then
    return key
  end
  for _, join_obj in pairs(self._join_keys) do
    if join_obj.model.table_name == self.table_name and join_obj.fk_model.fields[key] then
      return join_obj.fk_alias .. '.' .. key
    end
  end
  return key
end

---@param self Sql
---@param join_args table|string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.join(self, join_args, key, op, val)
  if type(join_args) == 'table' then
    self:_register_join_model(join_args, "INNER")
  elseif self.model.foreign_keys[join_args] then
    local fk = self.model.foreign_keys[join_args]
    self:_register_join_model({
      model = self.model,
      column = join_args,
      fk_model = fk.reference,
      fk_column = fk.reference_column,
      fk_alias = fk.reference.table_name
    }, "INNER")
  else
    Sql._base_join(self, join_args, key, op, val)
  end
  return self
end

---@param self Sql
---@param join_args table|string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.inner_join(self, join_args, key, op, val)
  if type(join_args) == 'table' then
    self:_register_join_model(join_args, "INNER")
  else
    Sql._base_join(self, join_args, key, op, val)
  end
  return self
end

---@param self Sql
---@param join_args table|string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.left_join(self, join_args, key, op, val)
  if type(join_args) == 'table' then
    self:_register_join_model(join_args, "LEFT")
  else
    Sql._base_left_join(self, join_args, key, op, val)
  end
  return self
end

---@param self Sql
---@param join_args table|string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.right_join(self, join_args, key, op, val)
  if type(join_args) == 'table' then
    self:_register_join_model(join_args, "RIGHT")
  else
    Sql._base_right_join(self, join_args, key, op, val)
  end
  return self
end

---@param self Sql
---@param join_args table|string
---@param key string
---@param op string
---@param val DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.full_join(self, join_args, key, op, val)
  if type(join_args) == 'table' then
    self:_register_join_model(join_args, "FULL")
  else
    Sql._base_full_join(self, join_args, key, op, val)
  end
  return self
end

---@param self Sql
---@param rows Records|Sql
---@param columns? string[]
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.insert(self, rows, columns)
  if not is_sql_instance(rows) then
    ---@cast rows Records
    if not self._skip_validate then
      ---@diagnostic disable-next-line: cast-local-type
      rows, columns = self.model:validate_create_data(rows, columns)
      if rows == nil then
        error(columns)
      end
    end
    ---@diagnostic disable-next-line: cast-local-type, param-type-mismatch
    rows, columns = self.model:prepare_db_rows(rows, columns)
    if rows == nil then
      error(columns)
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    return Sql._base_insert(self, rows, columns)
  else
    ---@cast rows Sql
    return Sql._base_insert(self, rows, columns)
  end
end

---@param self Sql
---@param row Record|Sql|string
---@param columns? string[]
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.update(self, row, columns)
  if type(row) == 'string' then
    return Sql._base_update(self, row)
  elseif not is_sql_instance(row) then
    local err
    ---@cast row Record
    if not self._skip_validate then
      ---@diagnostic disable-next-line: cast-local-type
      row, err = self.model:validate_update(row, columns)
      if row == nil then
        error(err)
      end
    end
    ---@diagnostic disable-next-line: cast-local-type
    row, columns = self.model:prepare_db_rows(row, columns, true)
    if row == nil then
      error(columns)
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    return Sql._base_update(self, row, columns)
  else
    ---@cast row Sql
    return Sql._base_update(self, row, columns)
  end
end

---@param self Sql
---@param rows Record[]
---@param key Keys
---@param columns? string[]
---@return Sql|XodelInstance[]
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.merge(self, rows, key, columns)
  if #rows == 0 then
    error("empty rows passed to merge")
  end
  if not self._skip_validate then
    ---@diagnostic disable-next-line: cast-local-type
    rows, key, columns = self.model:validate_create_rows(rows, key, columns)
    if rows == nil then
      error(key)
    end
  end
  ---@diagnostic disable-next-line: cast-local-type, param-type-mismatch
  rows, columns = self.model:prepare_db_rows(rows, columns, false)
  if rows == nil then
    error(columns)
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  Sql._base_merge(self, rows, key, columns):compact()
  if not self._returning then
    self:returning(key)
  end
  if self._commit == nil or self._commit then
    return self:exec()
  else
    return self
  end
end

---@param self Sql
---@param rows Record[]
---@param key Keys
---@param columns? string[]
---@return Sql|XodelInstance[]
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.upsert(self, rows, key, columns)
  if #rows == 0 then
    error("empty rows passed to merge")
  end
  if not self._skip_validate then
    ---@diagnostic disable-next-line: cast-local-type
    rows, key, columns = self.model:validate_create_rows(rows, key, columns)
    if rows == nil then
      error(key)
    end
  end
  ---@diagnostic disable-next-line: cast-local-type, param-type-mismatch
  rows, columns = self.model:prepare_db_rows(rows, columns, false)
  if rows == nil then
    error(columns)
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  Sql._base_upsert(self, rows, key, columns):compact()
  if not self._returning then
    self:returning(key)
  end
  if self._commit == nil or self._commit then
    return self:exec()
  else
    return self
  end
end

---@param self Sql
---@param rows Record[]
---@param key Keys
---@param columns? string[]
---@return Sql|XodelInstance[]
---@diagnostic disable-next-line: duplicate-set-field
function ModelSql.updates(self, rows, key, columns)
  if #rows == 0 then
    error("empty rows passed to merge")
  end
  if not self._skip_validate then
    ---@diagnostic disable-next-line: cast-local-type
    rows, key, columns = self.model:validate_update_rows(rows, key, columns)
    if rows == nil then
      error(columns)
    end
  end
  ---@diagnostic disable-next-line: cast-local-type, param-type-mismatch
  rows, columns = self.model:prepare_db_rows(rows, columns, true)
  if rows == nil then
    error(columns)
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  Sql._base_updates(self, rows, key, columns):compact()
  if not self._returning then
    self:returning(key)
  end
  if self._commit == nil or self._commit then
    return self:exec()
  else
    return self
  end
end

---@param self Sql
---@param keys Record[]
---@param columns string[]
---@return Sql|XodelInstance[]
function ModelSql.get_multiple(self, keys, columns)
  if self._commit == nil or self._commit then
    return Sql._base_get_multiple(self, keys, columns):exec()
  else
    return Sql._base_get_multiple(self, keys, columns)
  end
end

---@param self Sql
---@return Array<XodelInstance>
function ModelSql.exec(self)
  local statement = self:statement()
  local records = assert(self.model:query(statement, self._compact))
  if self._raw or self._compact or self._update or self._insert or self._delete then
    ---@cast records Array<Record>
    return Array:new(records)
  else
    ---@type Xodel
    local cls = self.model
    if not self._load_fk then
      for i, record in ipairs(records) do
        records[i] = cls:load(record)
      end
    else
      ---@type {[string]:Field}
      local fields = cls.fields
      local field_names = cls.field_names
      for i, record in ipairs(records) do
        for _, name in ipairs(field_names) do
          local field = fields[name]
          local value = record[name]
          if value ~= nil then
            local fk_model = self._load_fk[name]
            if not fk_model then
              if not field.load then
                record[name] = value
              else
                record[name] = field:load(value)
              end
            else
              -- _load_fk means reading attributes of a foreignkey,
              -- so the on-demand reading mode of foreignkey_db_to_lua_validator is not proper here
              record[name] = fk_model:load(get_foreign_object(record, name .. "__"))
            end
          end
        end
        records[i] = cls:create_record(record)
      end
    end
    ---@cast records Array<XodelInstance>
    return Array:new(records)
  end
end

---@param self Sql
---@param cond? table|string|function
---@param op? string
---@param dval? DBValue
---@return integer?, string?
function ModelSql.count(self, cond, op, dval)
  local res, err
  if cond ~= nil then
    res, err = self:select("count(*)"):where(cond, op, dval):compact():exec()
  else
    res, err = self:select("count(*)"):compact():exec()
  end
  if res == nil then
    return nil, err
  else
    return res[1][1]
  end
end

---@param self Sql
---@param rows Records|Sql
---@param columns? string[]
---@return Sql
function ModelSql.create(self, rows, columns)
  return self:insert(rows, columns):execr()
end

---@param self Sql
---@return boolean
function ModelSql.exists(self)
  local statement = string_format("SELECT EXISTS (%s)", self:select(""):limit(1):compact():statement())
  local res, err = self.model:query(statement, self._compact)
  if res == nil then
    error(err)
  else
    return res[1][1]
  end
end

---@param self Sql
---@return Sql
function ModelSql.compact(self)
  self._compact = true
  return self
end

---@param self Sql
---@return Sql
function ModelSql.raw(self)
  self._raw = true
  return self
end

---@param self Sql
---@param bool boolean
---@return Sql
function ModelSql.commit(self, bool)
  if bool == nil then
    bool = true
  end
  self._commit = bool
  return self
end

---@param self Sql
---@param bool? boolean
---@return Sql
function ModelSql.skip_validate(self, bool)
  if bool == nil then
    bool = true
  end
  self._skip_validate = bool
  return self
end

---@param self Sql
---@param depth? integer
---@return Record[]
function ModelSql.flat(self, depth)
  return self:compact():execr():flat(depth)
end

---@param self Sql
---@param cond? table|string|function
---@param op? string
---@param dval? DBValue
---@return XodelInstance?, number?
function ModelSql.try_get(self, cond, op, dval)
  local records
  if cond ~= nil then
    if type(cond) == 'table' and next(cond) == nil then
      error("empty condition table is not allowed")
    end
    records = self:where(cond, op, dval):limit(2):exec()
  else
    records = self:limit(2):exec()
  end
  if #records == 1 then
    return records[1]
  else
    return nil, #records
  end
end

---@param self Sql
---@param cond? table|string|function
---@param op? string
---@param dval? DBValue
---@return XodelInstance
function ModelSql.get(self, cond, op, dval)
  local record, record_number = self:try_get(cond, op, dval)
  if not record then
    if record_number == 0 then
      error("record not found")
    else
      error("multiple records returned: " .. record_number)
    end
  else
    return record
  end
end

---@param self Sql
---@param params table
---@param defaults? table
---@return XodelInstance, boolean
function ModelSql.get_or_create(self, params, defaults)
  local values_list, insert_columns = self:_get_insert_values_token(dict(params, defaults))
  local columns_token = as_token(insert_columns)
  local insert_sql = string_format("(INSERT INTO %s(%s) SELECT %s WHERE NOT EXISTS (%s) RETURNING %s, TRUE)",
    self.table_name,
    columns_token,
    as_literal_without_brackets(values_list),
    self:select(1):where(params),
    columns_token
  )
  local inserted_set = ModelSql:new { model = self.model, table_name = "new_records" }
      :with("new_records", insert_sql)
      :_base_select(columns_token):_base_select("TRUE AS __is_inserted__")
  local selected_set = self.model:create_sql():where(params):select(columns_token):select("FALSE AS __is_inserted__")
  local records = inserted_set:union_all(selected_set):exec()
  if #records > 1 then
    error("multiple records returned")
  end
  local ins = records[1]
  ---@diagnostic disable-next-line: undefined-field
  local created = ins.__is_inserted__
  ins.__is_inserted__ = nil
  return ins, created
end

---@param self Sql
---@return Set
function ModelSql.as_set(self)
  return self:compact():execr():flat():as_set()
end

---@param self Sql
---@return table|Array<Record>
function ModelSql.execr(self)
  return self:raw():exec()
end

---@param self Sql
---@param fk_name string
---@param select_names string[]
---@param ... string
---@return Sql
function ModelSql.load_fk(self, fk_name, select_names, ...)
  local fk = self.model.foreign_keys[fk_name]
  if fk == nil then
    error(fk_name .. " is not a valid forein key name for " .. self.table_name)
  end
  local fk_model = fk.reference
  local join_key = fk_name .. '__' .. fk_model.table_name
  local join_obj = self:_register_join_model {
    join_key = join_key,
    column = fk_name,
    fk_model = fk_model,
    fk_column = fk.reference_column
  }
  if not self._load_fk then
    self._load_fk = {}
  end
  self._load_fk[fk_name] = fk_model
  self:select(fk_name)
  if not select_names then
    return self
  end
  local right_alias = join_obj.fk_alias
  local fks
  if type(select_names) == 'table' then
    local res = {}
    for _, fkn in ipairs(select_names) do
      assert(fk_model.fields[fkn], "invalid field name for fk model: " .. fkn)
      res[#res + 1] = string_format("%s.%s AS %s__%s", right_alias, fkn, fk_name, fkn)
    end
    fks = table_concat(res, ', ')
  elseif select_names == '*' then
    local res = {}
    for i, fkn in ipairs(fk_model.field_names) do
      res[#res + 1] = string_format("%s.%s AS %s__%s", right_alias, fkn, fk_name, fkn)
    end
    fks = table_concat(res, ', ')
  elseif type(select_names) == 'string' then
    assert(fk_model.fields[select_names], "invalid field name for fk model: " .. select_names)
    fks = string_format("%s.%s AS %s__%s", right_alias, select_names, fk_name, select_names)
    for i = 1, select("#", ...) do
      local fkn = select(i, ...)
      assert(fk_model.fields[fkn], "invalid field name for fk model: " .. fkn)
      fks = string_format("%s, %s.%s AS %s__%s", fks, right_alias, fkn, fk_name, fkn)
    end
  else
    error(string_format("invalid argument type %s for load_fk", type(select_names)))
  end
  return Sql._base_select(self, fks)
end

---@param model Xodel
---@return table
local function make_record_meta(model)
  local RecordMeta = dict(Object, {})

  RecordMeta.__index = RecordMeta

  function RecordMeta.__call(self, data)
    for k, v in pairs(data) do
      self[k] = v
    end
    return self
  end

  function RecordMeta.delete(self, key)
    key = model:check_unique_key(key or model.primary_key)
    if self[key] == nil then
      error("empty value for delete key:" .. key)
    end
    return model:create_sql():delete { [key] = self[key] }:returning(key):exec()
  end

  function RecordMeta.save(self, names, key)
    return model:save(self, names, key)
  end

  function RecordMeta.save_create(self, names, key)
    return model:save_create(self, names, key)
  end

  function RecordMeta.save_update(self, names, key)
    return model:save_update(self, names, key)
  end

  function RecordMeta.validate(self, names, key)
    return model:validate(self, names, key)
  end

  function RecordMeta.validate_update(self, names)
    return model:validate_update(self, names)
  end

  function RecordMeta.validate_create(self, names)
    return model:validate_create(self, names)
  end

  return setmetatable(RecordMeta, model)
end

local function create_model_proxy(Model)
  local proxy = { __model__ = Model }
  local function __index(_, k)
    local sql_k = ModelSql[k]
    if sql_k ~= nil then
      if type(sql_k) == 'function' then
        return function(_, ...)
          return sql_k(Model:create_sql(), ...)
        end
      else
        return sql_k
      end
    end
    local model_k = Model[k]
    if model_k ~= nil then
      if type(model_k) == 'function' then
        return function(cls, ...)
          if cls == proxy then
            return model_k(Model, ...)
          else
            error(string_format("calling model proxy method `%s` with first argument not being itself is not allowed", k))
          end
        end
      else
        return model_k
      end
    else
      return nil
    end
  end
  local function __newindex(t, k, v)
    Model[k] = v
  end

  return setmetatable(proxy, {
    __call = function(cls, attr)
      return cls:create_record(attr)
    end,
    __index = __index,
    __newindex = __newindex
  })
end

---@class Xodel
---@field __index Xodel
---@field __normalized__? boolean
---@field __is_model_class__? boolean
---@field __SQL_BUILDER__? boolean
---@field DEFAULT  fun():'DEFAULT'
---@field NULL  userdata
---@field as_token  fun(DBValue):string
---@field as_literal  fun(DBValue):string
---@field r  fun(string):fun():string
---@field make_field_from_json fun(table):Field
---@field RecordClass table
---@field extends? table
---@field admin? table
---@field table_name string
---@field label string
---@field fields {[string]:Field}
---@field field_names Array
---@field mixins? table[]
---@field abstract? boolean
---@field disable_auto_primary_key? boolean
---@field primary_key string
---@field default_primary_key? string
---@field names Array
---@field auto_now_name string
---@field foreign_keys table
---@field name_cache {[string]:string}
---@field clean? function
---@field name_to_label {[string]:string}
---@field label_to_name {[string]:string}
local Xodel = {
  __SQL_BUILDER__ = true,
  _query = default_query,
  NULL = NULL,
  make_field_from_json = make_field_from_json,
  token = Sql.token,
  DEFAULT = Sql.DEFAULT,
  as_token = Sql.as_token,
  as_literal = Sql.as_literal,
}
setmetatable(Xodel, {
  ---@param t Xodel
  ---@param ... ModelOpts
  ---@return Xodel
  __call = function(t, ...)
    return t:mix_with_base(...)
  end
})

Xodel.__index = Xodel

function Xodel.__call(cls, ...)
  return cls.new(cls, ...)
end

---@param cls Xodel
---@param statement string
---@param compact? any
---@return table?, string|number?
function Xodel.query(cls, statement, compact)
  return cls._query(statement, compact)
end

---@param cls Xodel
---@param self? table
---@return Xodel
function Xodel.new(cls, self)
  return setmetatable(self or {}, cls)
end

---@class ModelOpts
---@field __normalized__? boolean
---@field extends? table
---@field admin? table
---@field table_name? string
---@field label? string
---@field fields {[string]:table}
---@field field_names Array
---@field db_options? QueryOpts
---@field mixins? table[]
---@field abstract? boolean
---@field disable_auto_primary_key? boolean
---@field primary_key string
---@field default_primary_key? string


---@param cls Xodel
---@param options ModelOpts
---@return Xodel
function Xodel.create_model(cls, options)
  local XodelClass = cls:make_model_class(cls:normalize(options))
  return create_model_proxy(XodelClass)
end

---@param cls Xodel
---@return Sql
function Xodel.create_sql(cls)
  return ModelSql:new { model = cls, table_name = cls.table_name }
end

---@param cls Xodel
---@param model any
---@return boolean
function Xodel.is_model_class(cls, model)
  return type(model) == 'table' and model.__is_model_class__
end

---@param cls Xodel
---@param options ModelOpts
---@return ModelOpts
function Xodel.normalize(cls, options)
  local extends = options.extends
  local model = {
    admin = options.admin or {}
  }
  local opts_fields, opts_field_names = normalize_array_and_hash_fields(options.fields or {})
  local opts_names = options.field_names
  if not opts_names then
    if extends then
      opts_names = Array.concat(extends.field_names, opts_field_names):uniq()
    else
      opts_names = opts_field_names
    end
  end
  model.field_names = normalize_field_names(clone(opts_names))
  model.fields = {}
  for _, name in ipairs(model.field_names) do
    check_reserved(name)
    if cls[name] then
      error(string_format("field name '%s' conflicts with model class attributes", name))
    end
    local field = opts_fields[name]
    if not field then
      local tname = options.table_name or '[abstract model]'
      if extends then
        field = extends.fields[name]
        if not field then
          error(string_format("'%s' field name '%s' is not in fields and parent fields", tname, name))
        end
      else
        error(string_format("Model class '%s's field name '%s' is not in fields", tname, name))
      end
    elseif not is_field_class(field) then
      if extends then
        local pfield = extends.fields[name]
        if pfield then
          field = dict(pfield:get_options(), field)
          if pfield.model and field.model then
            -- ** 这里选择extends而非mixins, 有待观察
            field.model = cls:create_model {
              abstract = true,
              extends = pfield.model,
              fields = field.model.fields,
              field_names = field.model.field_names
            }
          end
        end
      else
        -- 以json形式定义了一个新的field
      end
    else
      -- 以class形式定义field, 不考虑和父类合并
    end
    if not is_field_class(field) then
      model.fields[name] = make_field_from_json(field, { name = name })
    else
      model.fields[name] = make_field_from_json(field:get_options(), { name = name, type = field.type })
    end
  end
  for key, value in pairs(options) do
    if model[key] == nil and not NON_MERGE_NAMES[key] then
      model[key] = value
    end
  end
  local abstract
  if options.abstract ~= nil then
    abstract = not not options.abstract
  else
    abstract = options.table_name == nil
  end
  model.abstract = abstract
  model.__normalized__ = true
  if options.mixins then
    return cls:merge_models { model, unpack(options.mixins) }
  else
    return model
  end
end

---@param cls Xodel
function Xodel.set_label_name_dict(cls)
  cls.label_to_name = {}
  cls.name_to_label = {}
  cls.name_cache = {}
  for name, field in pairs(cls.fields) do
    cls.label_to_name[field.label] = name
    cls.name_to_label[name] = field.label
    cls.name_cache[name] = cls.table_name .. "." .. name
  end
end

---@param cls Xodel
---@param opts ModelOpts
---@return Xodel
function Xodel.make_model_class(cls, opts)
  local model = dict(cls, {
    _query = opts.db_options and Query(opts.db_options) or cls._query,
    table_name = opts.table_name,
    admin = opts.admin,
    label = opts.label or opts.table_name,
    fields = opts.fields,
    field_names = opts.field_names,
    mixins = opts.mixins,
    extends = opts.extends,
    abstract = opts.abstract,
    primary_key = opts.primary_key,
    default_primary_key = opts.default_primary_key,
    disable_auto_primary_key = opts.disable_auto_primary_key
  })
  model.__index = model
  local pk_defined = false
  model.foreign_keys = {}
  model.names = Array {}
  for i, name in pairs(model.field_names) do
    local field = model.fields[name]
    local fk_model = field.reference
    if fk_model == "self" then
      fk_model = model
      field.reference = model
    end
    if fk_model then
      model.foreign_keys[name] = field
    end
    if field.primary_key then
      local pk_name = field.name
      assert(not pk_defined, string_format('duplicated primary key: "%s" and "%s"', pk_name, pk_defined))
      pk_defined = pk_name
      model.primary_key = pk_name
    elseif field.auto_now then
      model.auto_now_name = field.name
    elseif field.auto_now_add then
    else
      model.names:push(name)
    end
  end
  for _, field in pairs(model.fields) do
    if field.db_type == Field.basefield.NOT_DEFIEND then
      field.db_type = model.fields[field.reference_column].db_type
    end
  end
  model.__is_model_class__ = true
  if model.table_name then
    return model:materialize_with_table_name { table_name = model.table_name }
  else
    return model
  end
end

---@param cls Xodel
---@param opts {table_name:string, label?:string}
---@return Xodel
function Xodel.materialize_with_table_name(cls, opts)
  local table_name = opts.table_name
  local label = opts.label
  if not table_name then
    local names_hint = cls.field_names and cls.field_names:join(",") or "no field_names"
    error(string_format("you must define table_name for a non-abstract model (%s)", names_hint))
  end
  check_reserved(table_name)
  cls.table_name = table_name
  cls.label = cls.label or label or table_name
  cls.abstract = false
  if not cls.primary_key and not cls.disable_auto_primary_key then
    local pk_name = cls.default_primary_key or "id"
    cls.primary_key = pk_name
    cls.fields[pk_name] = Field.integer { name = pk_name, primary_key = true, serial = true }
    table_insert(cls.field_names, 1, pk_name)
  end
  cls:set_label_name_dict()
  for name, field in pairs(cls.fields) do
    if field.reference then
      field.table_name = table_name
    end
  end
  cls.RecordClass = make_record_meta(cls)
  return setmetatable(cls, {
    __newindex = disable_setting_model_attrs
  })
end

---@param cls Xodel
---@param ... ModelOpts
---@return Xodel
function Xodel.mix_with_base(cls, ...)
  return cls:mix(base_model, ...)
end

---@param cls Xodel
---@param ... ModelOpts
---@return Xodel
function Xodel.mix(cls, ...)
  return create_model_proxy(cls:make_model_class(cls:merge_models { ... }))
end

---@param cls Xodel
---@param models ModelOpts[]
---@return ModelOpts
function Xodel.merge_models(cls, models)
  if #models < 2 then
    error("provide at least two models to merge")
  elseif #models == 2 then
    return cls:merge_model(unpack(models))
  else
    local merged = models[1]
    for i = 2, #models do
      merged = cls:merge_model(merged, models[i])
    end
    return merged
  end
end

---@param cls Xodel
---@param a ModelOpts
---@param b ModelOpts
---@return ModelOpts
function Xodel.merge_model(cls, a, b)
  local A = a.__normalized__ and a or cls:normalize(a)
  local B = b.__normalized__ and b or cls:normalize(b)
  local C = {}
  local field_names = (A.field_names + B.field_names):uniq()
  local fields = {}
  for i, name in ipairs(field_names) do
    local af = A.fields[name]
    local bf = B.fields[name]
    if af and bf then
      fields[name] = Xodel:merge_field(af, bf)
    elseif af then
      fields[name] = af
    elseif bf then
      fields[name] = bf
    else
      error(
        string_format("can't find field %s for model %s and %s", name, A.table_name, B.table_name))
    end
  end
  -- merge的时候abstract应该当做可合并的属性
  for i, M in ipairs { A, B } do
    for key, value in pairs(M) do
      if not NON_MERGE_NAMES[key] then
        C[key] = value
      end
    end
  end
  C.field_names = field_names
  C.fields = fields
  return cls:normalize(C)
end

---@param cls Xodel
---@param a Field
---@param b Field
---@return Field
function Xodel.merge_field(cls, a, b)
  local aopts = a.__is_field_class__ and a:get_options() or clone(a)
  local bopts = b.__is_field_class__ and b:get_options() or clone(b)
  local options = dict(aopts, bopts)
  if aopts.model and bopts.model then
    options.model = cls:merge_model(aopts.model, bopts.model)
  end
  return make_field_from_json(options)
end

---@param cls Xodel
function Xodel.to_json(cls)
  return {
    admin = cls.admin,
    label = cls.label or cls.table_name,
    table_name = cls.table_name,
    primary_key = cls.primary_key,
    names = cls.names,
    field_names = cls.field_names,
    label_to_name = cls.label_to_name,
    name_to_label = cls.name_to_label,
    fields = Object.from_entries(cls.field_names:map(function(name)
      return { name, cls.fields[name]:json() }
    end))
  }
end

---@param cls Xodel
function Xodel.to_camel_json(cls)
  local model_json = cls:to_json()
  for key, field in pairs(model_json.fields) do
    field.type = utils.snake_to_camel(field.type)
  end
  local res = utils.to_camel_json(model_json)
  local fields = {}
  for key, field in pairs(res.fields) do
    fields[utils.camel_to_snake(key)] = field
  end
  res.fields = fields
  local nameToLabel = {}
  for key, field in pairs(res.nameToLabel) do
    nameToLabel[utils.camel_to_snake(key)] = field
  end
  res.nameToLabel = nameToLabel
  return res
end

---@param cls Xodel
---@return Record[]
function Xodel.all(cls)
  local records = assert(cls:query("SELECT * FROM " .. cls.table_name))
  for i = 1, #records do
    records[i] = cls:load(records[i])
  end
  return setmetatable(records, Array)
end

---@param cls Xodel
---@param input Record
---@param names? string[]
---@param key?  string
---@return XodelInstance?, ValidateError?
function Xodel.save(cls, input, names, key)
  key = key or cls.primary_key
  if rawget(input, key) ~= nil then
    return cls:save_update(input, names, key)
  else
    return cls:save_create(input, names, key)
  end
end

---@param cls Xodel
---@param key  string
---@return string
function Xodel.check_unique_key(cls, key)
  local pkf = cls.fields[key]
  if not pkf then
    error("invalid field name: " .. key)
  end
  if not (pkf.primary_key or pkf.unique) then
    error(string_format("field '%s' is not primary_key or not unique", key))
  end
  return key
end

---@param cls Xodel
---@param input Record
---@param names? string[]
---@param key?  string
---@return XodelInstance?, ValidateError?
function Xodel.save_create(cls, input, names, key)
  local data, err = cls:validate_create(input, names)
  if data == nil then
    return nil, err
  end
  local prepared, perr = cls:prepare_for_db(data)
  if prepared == nil then
    return nil, perr
  end
  key = key or cls.primary_key
  local created = cls:create_sql():_base_insert(prepared):_base_returning(key):execr()
  data[key] = created[1][key]
  return cls:create_record(data)
end

---@param cls Xodel
---@param input Record
---@param names? string[]
---@param key?  string
---@return XodelInstance?, ValidateError?
function Xodel.save_update(cls, input, names, key)
  local data, err = cls:validate_update(input, names)
  if data == nil then
    return nil, err
  end
  if not key then
    key = cls.primary_key
  else
    key = cls:check_unique_key(key)
  end
  local look_value = input[key]
  if look_value == nil then
    error("no primary or unique key value for save_update")
  end
  local prepared, perr = cls:prepare_for_db(data, names, true)
  if prepared == nil then
    ---@cast perr ValidateError
    return nil, perr
  end
  local updated = cls:create_sql():_base_update(prepared):where { [key] = look_value }
      :_base_returning(key):execr()
  ---@cast updated Record
  if updated.affected_rows == 1 then
    data[key] = updated[1][key]
    return cls:create_record(data)
  elseif updated.affected_rows == 0 then
    error(string_format("update failed, record does not exist(model:%s, key:%s, value:%s)", cls.table_name,
      key, look_value))
  else
    error(string_format("expect 1 but %s records are updated(model:%s, key:%s, value:%s)",
      updated.affected_rows,
      cls.table_name,
      key,
      look_value))
  end
end

---@param cls Xodel
---@param data Record
---@param columns? string[]
---@param is_update? boolean
---@return Record
---@overload fun(cls:Xodel, data:Record, columns?:string[],is_update?:boolean):nil, ValidateError
function Xodel.prepare_for_db(cls, data, columns, is_update)
  local prepared = {}
  for _, name in ipairs(columns or cls.names) do
    local field = cls.fields[name]
    if not field then
      error(string_format("invalid field name '%s' for model '%s'", name, cls.table_name))
    end
    local value = data[name]
    if field.prepare_for_db and value ~= nil then
      local val, err = field:prepare_for_db(value, data)
      if val == nil and err then
        return nil, cls:make_field_error(name, err)
      else
        prepared[name] = val
      end
    else
      prepared[name] = value
    end
  end
  if is_update and cls.auto_now_name then
    prepared[cls.auto_now_name] = ngx_localtime()
  end
  return prepared
end

---@param cls Xodel
---@param input Record
---@param names? string[]
---@param key? string
---@return Record?, ValidateError?
function Xodel.validate(cls, input, names, key)
  if rawget(input, key or cls.primary_key) ~= nil then
    return cls:validate_update(input, names)
  else
    return cls:validate_create(input, names)
  end
end

---@param cls Xodel
---@param input Record
---@param names? string[]
---@return Record?, ValidateError?
function Xodel.validate_create(cls, input, names)
  local data = {}
  local value, err
  for _, name in ipairs(names or cls.names) do
    local field = cls.fields[name]
    if not field then
      error(string_format("invalid field name '%s' for model '%s'", name, cls.table_name))
    end
    value, err = field:validate(rawget(input, name), input)
    if err ~= nil then
      return nil, cls:make_field_error(name, err)
    elseif field.default and (value == nil or value == "") then
      if type(field.default) ~= "function" then
        value = field.default
      else
        value, err = field.default(input)
        if value == nil then
          return nil, cls:make_field_error(name, err)
        end
      end
    end
    data[name] = value
  end
  if not cls.clean then
    return data
  else
    local res, clean_err = cls:clean(data)
    if res == nil then
      return nil, cls:parse_error_message(clean_err)
    else
      return res
    end
  end
end

---@param cls Xodel
---@param input Record
---@param names? string[]
---@return Record
---@overload fun(cls:Xodel, input:Record, names?:string[]):nil, ValidateError
function Xodel.validate_update(cls, input, names)
  local data = {}
  local value, err
  for _, name in ipairs(names or cls.names) do
    local field = cls.fields[name]
    if not field then
      error(string_format("invalid field name '%s' for model '%s'", name, cls.table_name))
    end
    value = rawget(input, name)
    if value ~= nil then
      value, err = field:validate(value, input)
      if err ~= nil then
        return nil, cls:make_field_error(name, err)
      elseif value == nil then
        -- value is nil again after validate,its a non-required field whose value is empty string.
        -- data[name] = field.get_empty_value_to_update(input)
        -- 这里统一用空白字符串占位,以便prepare_for_db处pairs能处理该name
        data[name] = ""
      else
        data[name] = value
      end
    end
  end
  if not cls.clean then
    return data
  else
    local res, clean_err = cls:clean(data)
    if res == nil then
      return nil, cls:parse_error_message(clean_err)
    else
      return res
    end
  end
end

---@param cls Xodel
---@param rows Records
---@param key Keys
---@return Records, Keys
---@overload fun(rows:Records, key:Keys):nil, ValidateError
function Xodel.check_upsert_key(cls, rows, key)
  assert(key, "no key for upsert")
  if rows[1] then
    ---@cast rows Record[]
    if type(key) == "string" then
      for i, row in ipairs(rows) do
        if row[key] == nil or row[key] == '' then
          return nil, cls:make_field_error(key, "不能为空", i)
        end
      end
    else
      for i, row in ipairs(rows) do
        for _, k in ipairs(key) do
          if row[k] == nil or row[k] == '' then
            return nil, cls:make_field_error(k, "不能为空", i)
          end
        end
      end
    end
  elseif type(key) == "string" then
    ---@cast rows Record
    if rows[key] == nil or rows[key] == '' then
      return nil, cls:make_field_error(key, "不能为空")
    end
  else
    ---@cast rows Record
    for _, k in ipairs(key) do
      if rows[k] == nil or rows[k] == '' then
        return nil, cls:make_field_error(k, "不能为空")
      end
    end
  end
  return rows, key
end

function Xodel.make_field_error(cls, name, err, index)
  return { name = name, message = err, label = cls.fields[name].label, http_code = 422, index = index }
end

---@param cls Xodel
---@param err ValidateError
---@return ValidateErrorObject
function Xodel.parse_error_message(cls, err)
  if type(err) == 'table' then
    return err
  end
  local captured = match(err, '^(?<name>.+?)~(?<message>.+?)$', 'josui')
  if not captured then
    error("can't parse this model error message: " .. err)
  else
    local name = captured.name
    local message = captured.message
    local label = cls.name_to_label[name]
    return { name = name, err = message, label = label, http_code = 422 } -- string_format("%s：%s", name, message)
  end
end

---@param cls Xodel
---@param data Record
---@return XodelInstance
function Xodel.load(cls, data)
  for _, name in ipairs(cls.names) do
    local field = cls.fields[name]
    local value = data[name]
    if value ~= nil then
      if not field.load then
        data[name] = value
      else
        data[name] = field:load(value)
      end
    end
  end
  return cls:create_record(data)
end

---@param cls Xodel
---@param rows Record|Record[]
---@param columns? string[]
---@return Records?, string[]|ValidateError
function Xodel.validate_create_data(cls, rows, columns)
  local err_obj, cleaned
  columns = columns or cls.names
  if rows[1] then
    ---@cast rows Record[]
    cleaned = {}
    for i, row in ipairs(rows) do
      ---@diagnostic disable-next-line: cast-local-type
      row, err_obj = cls:validate_create(row, columns)
      if row == nil then
        err_obj.index = i
        ---@cast err_obj ValidateError
        return nil, err_obj
      end
      cleaned[i] = row
    end
  else
    ---@cast rows Record
    cleaned, err_obj = cls:validate_create(rows, columns)
    if err_obj then
      return nil, err_obj
    end
  end
  return cleaned, columns
end

---@param cls Xodel
---@param rows Record|Record[]
---@param columns? string[]
---@return Records?, string[]|ValidateError
function Xodel.validate_update_data(cls, rows, columns)
  local err_obj, cleaned
  columns = columns or cls.names
  if rows[1] then
    cleaned = {}
    for i, row in ipairs(rows) do
      ---@diagnostic disable-next-line: cast-local-type
      row, err_obj = cls:validate_update(row, columns)
      if row == nil then
        err_obj.index = i
        ---@cast err_obj ValidateError
        return nil, err_obj
      end
      cleaned[i] = row
    end
  else
    cleaned, err_obj = cls:validate_update(rows, columns)
    if err_obj then
      return nil, err_obj
    end
  end
  return cleaned, columns
end

---@param cls Xodel
---@param rows Records
---@param key Keys
---@param columns? string[]
---@return Records, Keys, Keys
---@overload fun(cls:Xodel, rows:Records, key:Keys, columns?: string[]):nil, ValidateError
function Xodel.validate_create_rows(cls, rows, key, columns)
  local checked_rows, checked_key = cls:check_upsert_key(rows, key or cls.primary_key)
  if checked_rows == nil then
    return nil, checked_key
  end
  local cleaned_rows, cleaned_columns = cls:validate_create_data(checked_rows, columns)
  if cleaned_rows == nil then
    return nil, cleaned_columns
  end
  return cleaned_rows, checked_key, cleaned_columns
end

---@param cls Xodel
---@param rows Records
---@param key Keys
---@param columns? string[]
---@return Records, Keys, Keys
---@overload fun(cls:Xodel, rows:Records, key:Keys, columns?: string[]):nil, ValidateError
function Xodel.validate_update_rows(cls, rows, key, columns)
  local checked_rows, checked_key = cls:check_upsert_key(rows, key or cls.primary_key)
  if checked_rows == nil then
    return nil, checked_key
  end
  local cleaned_rows, cleaned_columns = cls:validate_update_data(checked_rows, columns)
  if cleaned_rows == nil then
    return nil, cleaned_columns
  end
  return cleaned_rows, checked_key, cleaned_columns
end

---@param cls Xodel
---@param rows Records
---@param columns? string[]
---@param is_update? boolean
---@return Records?, string[]|ValidateError
function Xodel.prepare_db_rows(cls, rows, columns, is_update)
  local err, cleaned
  columns = columns or utils.get_keys(rows)
  if rows[1] then
    ---@cast rows Record[]
    cleaned = {}
    for i, row in ipairs(rows) do
      ---@diagnostic disable-next-line: cast-local-type
      row, err = cls:prepare_for_db(row, columns, is_update)
      if err ~= nil then
        err.index = i
        return nil, err
      end
      cleaned[i] = row
    end
  else
    ---@cast rows Record
    cleaned, err = cls:prepare_for_db(rows, columns, is_update)
    if err ~= nil then
      return nil, err
    end
  end
  if is_update then
    local utime = cls.auto_now_name
    if utime and not Array(columns):includes(utime) then
      columns[#columns + 1] = utime
    end
    return cleaned, columns
  else
    return cleaned, columns
  end
end

---@param cls Xodel
---@param row any
---@return boolean
function Xodel.is_instance(cls, row)
  return is_sql_instance(row)
end

---@param cls Xodel
---@param kwargs table
---@return Array<XodelInstance>
function Xodel.filter(cls, kwargs)
  return cls:create_sql():where(kwargs):exec()
end

---@param cls Xodel
---@param data table
---@return XodelInstance
function Xodel.create_record(cls, data)
  return setmetatable(data, cls.RecordClass)
end

local whitelist = { DEFAULT = true, as_token = true, as_literal = true, __call = true, new = true, token = true }
for k, v in pairs(ModelSql) do
  if type(v) == 'function' and not whitelist[k] then
    assert(Xodel[k] == nil, "same function name appears:" .. k)
  end
end
return Xodel
