local nkeys = require "table.nkeys"
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
local table_new = table.new
local NULL = ngx.null

local PG_SET_MAP = {
  _union = 'UNION',
  _union_all = 'UNION ALL',
  _except = 'EXCEPT',
  _except_all = 'EXCEPT ALL',
  _intersect = 'INTERSECT',
  _intersect_all = 'INTERSECT ALL'
}
local NON_FOREIGN_KEY = 3
local END = 4
local COMPARE_OPERATORS = { lt = "<", lte = "<=", gt = ">", gte = ">=", ne = "<>", eq = "=" }


---@param s string
---@return fun():string
local function make_token(s)
  local function raw_token()
    return s
  end

  return raw_token
end

local DEFAULT = make_token("DEFAULT")

local function map(tbl, func)
  local res = {}
  for i = 1, #tbl do
    res[i] = func(tbl[i])
  end
  return res
end

local function flat(tbl)
  local res = {}
  for i = 1, #tbl do
    local t = tbl[i]
    if type(t) ~= "table" then
      res[#res + 1] = t
    else
      for _, e in ipairs(flat(t)) do
        res[#res + 1] = e
      end
    end
  end
  return res
end

local function list(t1, t2)
  local res = clone(t1)
  if t2 then
    for i = 1, #t2 do
      res[#res + 1] = t2[i]
    end
  end
  return res
end

local function _prefix_with_V(column)
  return "V." .. column
end

---@param row any
---@return boolean
local function is_sql_instance(row)
  local meta = getmetatable(row)
  return meta and meta.__SQL_BUILDER__
end

local function _escape_factory(is_literal, is_bracket)
  ---value escaper for lua value
  ---@param value DBValue
  ---@return string
  local function as_sql_token(value)
    local value_type = type(value)
    if "string" == value_type then
      if is_literal then
        return "'" .. (value:gsub("'", "''")) .. "'"
      else
        return value
      end
    elseif "number" == value_type then
      return tostring(value)
    elseif "boolean" == value_type then
      return value and "TRUE" or "FALSE"
    elseif "function" == value_type then
      return value()
    elseif "table" == value_type then
      if is_sql_instance(value) then
        return "(" .. value:statement() .. ")"
      elseif value[1] ~= nil then
        local token = table_concat(map(value, as_sql_token), ", ")
        if is_bracket then
          return "(" .. token .. ")"
        else
          return token
        end
      else
        error("empty table as a Xodel value is not allowed")
      end
    elseif NULL == value then
      return 'NULL'
    else
      error(string_format("don't know how to escape value: %s (%s)", value, value_type))
    end
  end

  return as_sql_token
end
local as_literal = _escape_factory(true, true)
local as_literal_without_brackets = _escape_factory(true, false)
local as_token = _escape_factory(false, false)

local function assemble_sql(opts)
  local statement
  if opts.update then
    local from = opts.from and " FROM " .. opts.from or ""
    local where = opts.where and " WHERE " .. opts.where or ""
    local returning = opts.returning and " RETURNING " .. opts.returning or ""
    statement = string_format("UPDATE %s SET %s%s%s%s", opts.table_name, opts.update, from, where, returning)
  elseif opts.insert then
    local returning = opts.returning and " RETURNING " .. opts.returning or ""
    statement = string_format("INSERT INTO %s %s%s", opts.table_name, opts.insert, returning)
  elseif opts.delete then
    local using = opts.using and " USING " .. opts.using or ""
    local where = opts.where and " WHERE " .. opts.where or ""
    local returning = opts.returning and " RETURNING " .. opts.returning or ""
    statement = string_format("DELETE FROM %s%s%s%s", opts.table_name, using, where, returning)
  else
    local from = opts.from or opts.table_name
    local where = opts.where and " WHERE " .. opts.where or ""
    local group = opts.group and " GROUP BY " .. opts.group or ""
    local having = opts.having and " HAVING " .. opts.having or ""
    local order = opts.order and " ORDER BY " .. opts.order or ""
    local limit = opts.limit and " LIMIT " .. opts.limit or ""
    local offset = opts.offset and " OFFSET " .. opts.offset or ""
    local distinct = opts.distinct and "DISTINCT " or ""
    local select = opts.select or "*"
    statement = string_format("SELECT %s%s FROM %s%s%s%s%s%s%s",
      distinct, select, from, where, group, having, order, limit, offset)
  end
  return opts.with and string_format("WITH %s %s", opts.with, statement) or statement
end

---@class Sql
---@field __index Sql
---@field __call fun(t:Sql, args:string|table):Sql
---@field __tostring fun(t:Sql):string
---@field as_token fun(value:DBValue): string
---@field as_literal fun(value:DBValue): string
---@field as_literal_without_brackets fun(value:DBValue): string
---@field token fun(s:string): fun():string
---@field NULL userdata
---@field DEFAULT  fun():'DEFAULT'
---@field table_name string
---@field _pcall? boolean
---@field _as?  string
---@field _with?  string
---@field _join?  string
---@field _distinct?  boolean
---@field _returning?  string
---@field _returning_args?  DBValue[]
---@field _insert?  string
---@field _update?  string
---@field _delete?  boolean
---@field _using?  string
---@field _select?  string
---@field _from?  string
---@field _where?  string
---@field _group?  string
---@field _having?  string
---@field _order?  string
---@field _limit?  number
---@field _offset?  number
---@field _union?  Sql | string
---@field _union_all?  Sql | string
---@field _except?  Sql | string
---@field _except_all?  Sql | string
---@field _intersect?  Sql | string
---@field _intersect_all?  Sql | string
local Sql = utils.class({
  __SQL_BUILDER__ = true,
  NULL = NULL,
  DEFAULT = DEFAULT,
  token = make_token,
  as_token = as_token,
  as_literal = as_literal,
  as_literal_without_brackets = as_literal_without_brackets,
}, {
  __call = function(t, args)
    if type(args) == 'string' then
      return t:new { table_name = args }
    else
      return t:new(args)
    end
  end,
  __tostring = function(self)
    return self:statement()
  end
})

---@param cls Sql
---@param self? table
---@return Sql
function Sql.new(cls, self)
  return setmetatable(self or {}, cls)
end

---@param self Sql
---@param a DBValue
---@param b? DBValue
---@param ...? DBValue
---@return Sql
function Sql._base_select(self, a, b, ...)
  local s = Sql._base_get_select_token(self, a, b, ...)
  if not self._select then
    self._select = s
  elseif s ~= nil and s ~= "" then
    self._select = self._select .. ", " .. s
  end
  return self
end

---@param self Sql
---@param a DBValue
---@param b? DBValue
---@param ...? DBValue
---@return string
function Sql._base_get_select_token(self, a, b, ...)
  if b == nil then
    if type(a) == 'table' then
      return Sql._base_get_select_token(self, unpack(a))
    else
      return as_token(a)
    end
  else
    local s = as_token(a) .. ", " .. as_token(b)
    for i = 1, select("#", ...) do
      s = s .. ", " .. as_token(select(i, ...))
    end
    return s
  end
end

---@param self Sql
---@param rows Records|Sql|string
---@param columns? string[]
---@return Sql
function Sql._base_insert(self, rows, columns)
  if type(rows) == "table" then
    if is_sql_instance(rows) then
      ---@cast rows Sql
      if rows._select then
        self:_set_select_subquery_insert_token(rows, columns)
      elseif rows._returning_args then
        self:_set_cud_subquery_insert_token(rows, columns)
      else
        error("select or returning args should be provided when inserting from a sub query")
      end
    elseif rows[1] then
      ---@cast rows Record[]
      self._insert = self:_get_bulk_insert_token(rows, columns)
    elseif next(rows) ~= nil then
      ---@cast rows Record
      self._insert = self:_get_insert_token(rows, columns)
    else
      error("can't pass empty table to Sql._base_insert")
    end
  elseif type(rows) == 'string' then
    self._insert = rows
  else
    error("invalid value type to Sql._base_insert:" .. type(rows))
  end
  return self
end

---@param self Sql
---@param row Record|string|Sql
---@param columns? string[]
---@return Sql
function Sql._base_update(self, row, columns)
  if is_sql_instance(row) then
    ---@cast row Sql
    self._update = self:_base_get_update_query_token(row, columns)
  elseif type(row) == "table" then
    self._update = self:_get_update_token(row, columns)
  else
    ---@cast row string
    self._update = row
  end
  return self
end

---@param self Sql
---@param rows Record[]
---@param key Keys
---@param columns? string[]
---@return Sql
function Sql._base_merge(self, rows, key, columns)
  rows, columns = self:_get_cte_values_literal(rows, columns, false)
  local cte_name = string_format("V(%s)", table_concat(columns, ", "))
  local cte_values = string_format("(VALUES %s)", as_token(rows))
  local join_cond = self:_get_join_conditions(key, "V", "T")
  local vals_columns = map(columns, _prefix_with_V)
  local insert_subquery = Sql:new { table_name = "V" }
      :_base_select(vals_columns)
      :_base_left_join("U AS T", join_cond)
      :_base_where_null("T." .. (key[1] or key))
  local updated_subquery
  if (type(key) == "table" and #key == #columns) or #columns == 1 then
    updated_subquery = Sql:new { table_name = "V" }
        :_base_select(vals_columns)
        :_base_join(self.table_name .. " AS T", join_cond)
  else
    updated_subquery = Sql:new { table_name = self.table_name, _as = "T" }
        :_base_update(self:_get_update_token_with_prefix(columns, key, "V"))
        :_base_from("V"):_base_where(join_cond)
        :_base_returning(vals_columns)
  end
  self:with(cte_name, cte_values):with("U", updated_subquery)
  return Sql._base_insert(self, insert_subquery, columns)
end

---@param self Sql
---@param rows Sql|Record[]
---@param key Keys
---@param columns? string[]
---@return Sql
function Sql._base_upsert(self, rows, key, columns)
  assert(key, "you must provide key for upsert(string or table)")
  if is_sql_instance(rows) then
    assert(columns ~= nil, "you must specify columns when use subquery as values of upsert")
    self._insert = self:_get_upsert_query_token(rows, key, columns)
  elseif rows[1] then
    self._insert = self:_get_bulk_upsert_token(rows, key, columns)
  else
    self._insert = self:_get_upsert_token(rows, key, columns)
  end
  return self
end

---@param self Sql
---@param rows Record[]|Sql
---@param key Keys
---@param columns? string[]
---@return Sql
function Sql._base_updates(self, rows, key, columns)
  if is_sql_instance(rows) then
    ---@cast rows Sql
    columns = columns or flat(rows._returning_args)
    local cte_name = string_format("V(%s)", table_concat(columns, ", "))
    local join_cond = self:_get_join_conditions(key, "V", self._as or self.table_name)
    self:with(cte_name, rows)
    return Sql._base_update(self, self:_get_update_token_with_prefix(columns, key, "V")):from("V"):where(join_cond)
  elseif #rows == 0 then
    error("empty rows passed to updates")
  else
    ---@cast rows Record[]
    rows, columns = self:_get_cte_values_literal(rows, columns, false)
    local cte_name = string_format("V(%s)", table_concat(columns, ", "))
    local cte_values = string_format("(VALUES %s)", as_token(rows))
    local join_cond = self:_get_join_conditions(key, "V", self._as or self.table_name)
    self:with(cte_name, cte_values)
    return Sql._base_update(self, self:_get_update_token_with_prefix(columns, key, "V")):from("V"):where(join_cond)
  end
end

---@param self Sql
---@param a DBValue
---@param b? DBValue
---@param ...? DBValue
---@return Sql
function Sql._base_returning(self, a, b, ...)
  local s = self:_base_get_select_token(a, b, ...)
  if not self._returning then
    self._returning = s
  elseif s ~= nil and s ~= "" then
    self._returning = self._returning .. ", " .. s
  else
    return self
  end
  if self._returning_args then
    self._returning_args = { self._returning_args, ... }
  else
    self._returning_args = { ... }
  end
  return self
end

---@param self Sql
---@param a string
---@param ... string
---@return Sql
function Sql._base_from(self, a, ...)
  if not self._from then
    self._from = Sql._base_get_select_token(self, a, ...)
  else
    self._from = self._from .. ", " .. Sql._base_get_select_token(self, a, ...)
  end
  return self
end

---@param self Sql
---@param right_table string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
function Sql._base_join(self, right_table, key, op, val)
  local join_token = self:_get_join_token("INNER", right_table, key, op, val)
  self._from = string_format("%s %s", self._from or self:get_table(), join_token)
  return self
end

---@param self Sql
---@param right_table string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
function Sql._base_left_join(self, right_table, key, op, val)
  local join_token = self:_get_join_token("LEFT", right_table, key, op, val)
  self._from = string_format("%s %s", self._from or self:get_table(), join_token)
  return self
end

---@param self Sql
---@param right_table string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
function Sql._base_right_join(self, right_table, key, op, val)
  local join_token = self:_get_join_token("RIGHT", right_table, key, op, val)
  self._from = string_format("%s %s", self._from or self:get_table(), join_token)
  return self
end

---@param self Sql
---@param right_table string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
function Sql._base_full_join(self, right_table, key, op, val)
  local join_token = self:_get_join_token("FULL", right_table, key, op, val)
  self._from = string_format("%s %s", self._from or self:get_table(), join_token)
  return self
end

---@param self Sql
---@param cond table|string|function
---@param op? string
---@param dval? DBValue
---@return Sql
function Sql._base_where(self, cond, op, dval)
  local where_token = self:_base_get_condition_token(cond, op, dval)
  return self:_handle_where_token(where_token, "(%s) AND (%s)")
end

---@param self Sql
---@param kwargs {[string|number]:any}
---@param logic? "AND"|"OR"
---@return string
function Sql._base_get_condition_token_from_table(self, kwargs, logic)
  local tokens = {}
  for k, value in pairs(kwargs) do
    if type(k) == "string" then
      tokens[#tokens + 1] = string_format("%s = %s", k, as_literal(value))
    else
      local token = Sql._base_get_condition_token(self, value)
      if token ~= nil and token ~= "" then
        tokens[#tokens + 1] = '(' .. token .. ')'
      end
    end
  end
  if logic == nil then
    return table_concat(tokens, " AND ")
  else
    return table_concat(tokens, " " .. logic .. " ")
  end
end

---@param self Sql
---@param cond table|string|function
---@param op? DBValue
---@param dval? DBValue
---@return string
function Sql._base_get_condition_token(self, cond, op, dval)
  if op == nil then
    local argtype = type(cond)
    if argtype == "table" then
      return Sql._base_get_condition_token_from_table(self, cond)
    elseif argtype == "string" then
      return cond
    elseif argtype == "function" then
      local old_where = self._where
      self._where = nil
      local res, err = cond(self)
      if res ~= nil then
        if res == self then
          local group_where = self._where
          if group_where == nil then
            error("no where token generate after calling condition function")
          else
            self._where = old_where
            return group_where
          end
        else
          self._where = old_where
          return res
        end
      else
        error(err or "nil returned in condition function")
      end
    else
      error("invalid condition type: " .. argtype)
    end
  elseif dval == nil then
    return string_format("%s = %s", cond, as_literal(op))
  else
    return string_format("%s %s %s", cond, op, as_literal(dval))
  end
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql._base_where_in(self, cols, range)
  local in_token = self:_get_in_token(cols, range)
  if self._where then
    self._where = string_format("(%s) AND %s", self._where, in_token)
  else
    self._where = in_token
  end
  return self
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql._base_where_not_in(self, cols, range)
  local not_in_token = self:_get_in_token(cols, range, "NOT IN")
  if self._where then
    self._where = string_format("(%s) AND %s", self._where, not_in_token)
  else
    self._where = not_in_token
  end
  return self
end

---@param self Sql
---@param col string
---@return Sql
function Sql._base_where_null(self, col)
  if self._where then
    self._where = string_format("(%s) AND %s IS NULL", self._where, col)
  else
    self._where = col .. " IS NULL"
  end
  return self
end

---@param self Sql
---@param col string
---@return Sql
function Sql._base_where_not_null(self, col)
  if self._where then
    self._where = string_format("(%s) AND %s IS NOT NULL", self._where, col)
  else
    self._where = col .. " IS NOT NULL"
  end
  return self
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql._base_where_between(self, col, low, high)
  if self._where then
    self._where = string_format("(%s) AND (%s BETWEEN %s AND %s)", self._where, col, low, high)
  else
    self._where = string_format("%s BETWEEN %s AND %s", col, low, high)
  end
  return self
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql._base_where_not_between(self, col, low, high)
  if self._where then
    self._where = string_format("(%s) AND (%s NOT BETWEEN %s AND %s)", self._where, col, low, high)
  else
    self._where = string_format("%s NOT BETWEEN %s AND %s", col, low, high)
  end
  return self
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql._base_or_where_in(self, cols, range)
  local in_token = self:_get_in_token(cols, range)
  if self._where then
    self._where = string_format("%s OR %s", self._where, in_token)
  else
    self._where = in_token
  end
  return self
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql._base_or_where_not_in(self, cols, range)
  local not_in_token = self:_get_in_token(cols, range, "NOT IN")
  if self._where then
    self._where = string_format("%s OR %s", self._where, not_in_token)
  else
    self._where = not_in_token
  end
  return self
end

---@param self Sql
---@param col string
---@return Sql
function Sql._base_or_where_null(self, col)
  if self._where then
    self._where = string_format("%s OR %s IS NULL", self._where, col)
  else
    self._where = col .. " IS NULL"
  end
  return self
end

---@param self Sql
---@param col string
---@return Sql
function Sql._base_or_where_not_null(self, col)
  if self._where then
    self._where = string_format("%s OR %s IS NOT NULL", self._where, col)
  else
    self._where = col .. " IS NOT NULL"
  end
  return self
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql._base_or_where_between(self, col, low, high)
  if self._where then
    self._where = string_format("%s OR (%s BETWEEN %s AND %s)", self._where, col, low, high)
  else
    self._where = string_format("%s BETWEEN %s AND %s", col, low, high)
  end
  return self
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql._base_or_where_not_between(self, col, low, high)
  if self._where then
    self._where = string_format("%s OR (%s NOT BETWEEN %s AND %s)", self._where, col, low, high)
  else
    self._where = string_format("%s NOT BETWEEN %s AND %s", col, low, high)
  end
  return self
end

---@param self Sql
---@return Sql
function Sql.pcall(self)
  self._pcall = true
  return self
end

---@param self Sql
---@param err ValidateError
---@param level? integer
---@return nil, ValidateError?
function Sql.error(self, err, level)
  if self._pcall then
    return nil, err
  else
    error(err, level)
  end
end

---@param self Sql
---@param rows Record[]
---@param columns string[]
---@return DBValue[][]
---@diagnostic disable-next-line: duplicate-set-field
function Sql._rows_to_array(self, rows, columns)
  local c = #columns
  local n = #rows
  local res = table_new(n, 0)
  for i = 1, n do
    res[i] = table_new(c, 0)
  end
  for i, col in ipairs(columns) do
    for j = 1, n do
      local v = rows[j][col]
      if v ~= nil and v ~= '' then
        res[j][i] = v
      else
        res[j][i] = NULL
      end
    end
  end
  return res
end

---@param self Sql
---@param row Record
---@param columns? string[]
---@return string[], string[]
function Sql._get_insert_values_token(self, row, columns)
  local value_list = {}
  if not columns then
    columns = {}
    for k, v in pairs(row) do
      table_insert(columns, k)
      table_insert(value_list, v)
    end
  else
    for _, col in pairs(columns) do
      local v = row[col]
      if v ~= nil then
        table_insert(value_list, v)
      else
        table_insert(value_list, DEFAULT)
      end
    end
  end
  return value_list, columns
end

---@param self Sql
---@param rows Record[]
---@param columns? string[]
---@return string[], string[]
function Sql._get_bulk_insert_values_token(self, rows, columns)
  columns = columns or utils.get_keys(rows)
  rows = self:_rows_to_array(rows, columns)
  return map(rows, as_literal), columns
end

---@param self Sql
---@param columns string[]
---@param key Keys
---@param table_name string
---@return string
function Sql._get_update_token_with_prefix(self, columns, key, table_name)
  local tokens = {}
  if type(key) == "string" then
    for i, col in ipairs(columns) do
      if col ~= key then
        table_insert(tokens, string_format("%s = %s.%s", col, table_name, col))
      end
    end
  else
    local sets = {}
    for i, k in ipairs(key) do
      sets[k] = true
    end
    for i, col in ipairs(columns) do
      if not sets[col] then
        table_insert(tokens, string_format("%s = %s.%s", col, table_name, col))
      end
    end
  end
  return table_concat(tokens, ", ")
end

---@param self Sql
---@param a DBValue
---@param b? DBValue
---@param ...? DBValue
---@return string
function Sql._get_select_token(self, a, b, ...)
  if b == nil then
    if type(a) == "table" then
      local tokens = {}
      for i = 1, #a do
        tokens[i] = self:_get_select_column(a[i])
      end
      return as_token(tokens)
    elseif type(a) == "string" then
      return self:_get_select_column(a) --[[@as string]]
    else
      return as_token(a)
    end
  else
    a = self:_get_select_column(a)
    b = self:_get_select_column(b)
    local s = as_token(a) .. ", " .. as_token(b)
    for i = 1, select("#", ...) do
      local name = select(i, ...)
      s = s .. ", " .. as_token(self:_get_select_column(name))
    end
    return s
  end
end

---@param self Sql
---@param a DBValue
---@param b? DBValue
---@param ...? DBValue
---@return string
function Sql._get_select_token_literal(self, a, b, ...)
  if b == nil then
    if type(a) == "table" then
      local tokens = {}
      for i = 1, #a do
        tokens[i] = as_literal(a[i])
      end
      return as_token(tokens)
    else
      return as_literal(a)
    end
  else
    local s = as_literal(a) .. ", " .. as_literal(b)
    for i = 1, select("#", ...) do
      local name = select(i, ...)
      s = s .. ", " .. as_literal(name)
    end
    return s
  end
end

---@param self Sql
---@param row Record
---@param columns? string[]
---@return string
function Sql._get_update_token(self, row, columns)
  local kv = {}
  if not columns then
    for k, v in pairs(row) do
      table_insert(kv, string_format("%s = %s", k, as_literal(v)))
    end
  else
    for _, k in ipairs(columns) do
      local v = row[k]
      table_insert(kv, string_format("%s = %s", k, v ~= nil and as_literal(v) or 'DEFAULT'))
    end
  end
  return table_concat(kv, ", ")
end

---@param self Sql
---@param name string
---@param token? Sql|DBValue
---@return string
function Sql._get_with_token(self, name, token)
  if token == nil then
    return name
  elseif is_sql_instance(token) then
    ---@cast token Sql
    return string_format("%s AS (%s)", name, token:statement())
  else
    return string_format("%s AS %s", name, token)
  end
end

---@param self Sql
---@param row Record
---@param columns? string[]
---@return string
function Sql._get_insert_token(self, row, columns)
  local values_list, insert_columns = self:_get_insert_values_token(row, columns)
  return string_format("(%s) VALUES %s", as_token(insert_columns), as_literal(values_list))
end

---@param self Sql
---@param rows Record[]
---@param columns? string[]
---@return string
function Sql._get_bulk_insert_token(self, rows, columns)
  rows, columns = self:_get_bulk_insert_values_token(rows, columns)
  return string_format("(%s) VALUES %s", as_token(columns), as_token(rows))
end

---@param self Sql
---@param sub_query Sql
---@param columns? string[]
function Sql._set_select_subquery_insert_token(self, sub_query, columns)
  local columns_token = as_token(columns or sub_query._select or "")
  if columns_token ~= "" then
    self._insert = string_format("(%s) %s", columns_token, sub_query:statement())
  else
    self._insert = sub_query:statement()
  end
end

---@param self Sql
---@param sub_query Sql
function Sql._set_cud_subquery_insert_token(self, sub_query, columns)
  local insert_columns = columns or flat(sub_query._returning_args)
  local cud_select_query = Sql:new { table_name = "d" }:_base_select(insert_columns)
  self:with(string_format("d(%s)", as_token(insert_columns)), sub_query)
  self._insert = string_format("(%s) %s", as_token(insert_columns), cud_select_query:statement())
end

---@param self Sql
---@param row Record
---@param key Keys
---@param columns? string[]
---@return string
function Sql._get_upsert_token(self, row, key, columns)
  local values_llist, insert_columns = self:_get_insert_values_token(row, columns)
  local insert_token = string_format("(%s) VALUES %s ON CONFLICT (%s)",
    as_token(insert_columns),
    as_literal(values_llist),
    self:_get_select_token(key))
  if (type(key) == "table" and #key == #insert_columns) or #insert_columns == 1 then
    return string_format("%s DO NOTHING", insert_token)
  else
    return string_format("%s DO UPDATE SET %s", insert_token,
      self:_get_update_token_with_prefix(insert_columns, key, "EXCLUDED"))
  end
end

---@param self Sql
---@param rows Record[]
---@param key Keys
---@param columns? string[]
---@return string
function Sql._get_bulk_upsert_token(self, rows, key, columns)
  rows, columns = self:_get_bulk_insert_values_token(rows, columns)
  local insert_token = string_format("(%s) VALUES %s ON CONFLICT (%s)", as_token(columns), as_token(rows),
    self:_base_get_select_token(key))
  if (type(key) == "table" and #key == #columns) or #columns == 1 then
    return string_format("%s DO NOTHING", insert_token)
  else
    return string_format("%s DO UPDATE SET %s", insert_token,
      self:_get_update_token_with_prefix(columns, key, "EXCLUDED"))
  end
end

---@param self Sql
---@param rows Sql
---@param key Keys
---@param columns string[]
---@return string
function Sql._get_upsert_query_token(self, rows, key, columns)
  local columns_token = self:_get_select_token(columns)
  local insert_token = string_format("(%s) %s ON CONFLICT (%s)", columns_token, rows:statement(),
    self:_get_select_token(key))
  if (type(key) == "table" and #key == #columns) or #columns == 1 then
    return string_format("%s DO NOTHING", insert_token)
  else
    return string_format("%s DO UPDATE SET %s", insert_token,
      self:_get_update_token_with_prefix(columns, key, "EXCLUDED"))
  end
end

---@param self Sql
---@param key string
---@param op? string
---@param val? DBValue
---@return string
function Sql._get_join_expr(self, key, op, val)
  if op == nil then
    return key
  elseif val == nil then
    return string_format("%s = %s", key, op)
  else
    return string_format("%s %s %s", key, op, val)
  end
end

---@param self Sql
---@param join_type JOIN_TYPE
---@param right_table string
---@param key string
---@param op? string
---@param val? DBValue
---@return string
function Sql._get_join_token(self, join_type, right_table, key, op, val)
  if key ~= nil then
    return string_format("%s JOIN %s ON (%s)", join_type, right_table, self:_get_join_expr(key, op, val))
  else
    return string_format("%s JOIN %s", join_type, right_table)
  end
end

---@param self Sql
---@param cols Keys
---@param range Sql|table|string
---@param op? string
---@return string
function Sql._get_in_token(self, cols, range, op)
  cols = as_token(cols)
  op = op or "IN"
  if type(range) == 'table' then
    if is_sql_instance(range) then
      return string_format("(%s) %s (%s)", cols, op, range:statement())
    else
      return string_format("(%s) %s %s", cols, op, as_literal(range))
    end
  else
    return string_format("(%s) %s %s", cols, op, range)
  end
end

---@param self Sql
---@param sub_select Sql
---@param columns? string[]
---@return string
function Sql._get_update_query_token(self, sub_select, columns)
  local columns_token = columns and self:_get_select_token(columns) or sub_select._select
  return string_format("(%s) = (%s)", columns_token, sub_select:statement())
end

---@param self Sql
---@param sub_select Sql
---@param columns? string[]
---@return string
function Sql._base_get_update_query_token(self, sub_select, columns)
  local columns_token = columns and self:_base_get_select_token(columns) or sub_select._select
  return string_format("(%s) = (%s)", columns_token, sub_select:statement())
end

---@param self Sql
---@param key Keys
---@param left_table string
---@param right_table string
---@return string
function Sql._get_join_conditions(self, key, left_table, right_table)
  if type(key) == "string" then
    return string_format("%s.%s = %s.%s", left_table, key, right_table, key)
  end
  local res = {}
  for _, k in ipairs(key) do
    res[#res + 1] = string_format("%s.%s = %s.%s", left_table, k, right_table, k)
  end
  return table_concat(res, " AND ")
end

---@param self Sql
---@param rows Record[]
---@param columns? string[]
---@param no_check? boolean
---@return string[], string[]
---@diagnostic disable-next-line: duplicate-set-field
function Sql._get_cte_values_literal(self, rows, columns, no_check)
  columns = columns or utils.get_keys(rows)
  rows = self:_rows_to_array(rows, columns)
  ---@type string[]
  local res = table_new(#rows)
  for i = 1, #rows, 1 do
    res[i] = as_literal(rows[i])
  end
  return res, columns
end

---@param self Sql
---@param join_type JOIN_TYPE
---@param join_table string
---@param join_cond string
function Sql._handle_join(self, join_type, join_table, join_cond)
  if self._update then
    self:from(join_table)
    self:where(join_cond)
  elseif self._delete then
    self:using(join_table)
    self:where(join_cond)
  elseif join_type == "INNER" then
    self:_base_join(join_table, join_cond)
  elseif join_type == "LEFT" then
    self:_base_left_join(join_table, join_cond)
  elseif join_type == "RIGHT" then
    self:_base_right_join(join_table, join_cond)
  else
    self:_base_full_join(join_table, join_cond)
  end
end

---@param self Sql
---@param key string
---@return string, string
---@diagnostic disable-next-line: duplicate-set-field
function Sql._get_where_key(self, key)
  local a, b = key:find("__", 1, true)
  if not a then
    return self:_get_column(key) --[[@as string]], "eq"
  end
  local e = key:sub(1, a - 1)
  local i, state
  local op = "eq"
  local field_name = e
  state = NON_FOREIGN_KEY
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
    else
      error(string_format("invalid cond table key parsing state %s with token %s", state, e))
    end
    if not a then
      break
    end
  end
  return field_name, op
end

---@param self Sql
---@param key string
---@return string
---@diagnostic disable-next-line: duplicate-set-field
function Sql._get_column(self, key)
  return key
end

---@param self Sql
---@param key DBValue
---@return DBValue
function Sql._get_select_column(self, key)
  if type(key) ~= 'string' then
    return key
  else
    return self:_get_column(key)
  end
end

---@param self Sql
---@param value DBValue
---@param key string
---@param op string
---@return string
function Sql._get_expr_token(self, value, key, op)
  if op == "eq" then
    return string_format("%s = %s", key, as_literal(value))
  elseif op == "in" then
    return string_format("%s IN %s", key, as_literal(value))
  elseif op == "notin" then
    return string_format("%s NOT IN %s", key, as_literal(value))
  elseif COMPARE_OPERATORS[op] then
    return string_format("%s %s %s", key, COMPARE_OPERATORS[op], as_literal(value))
  elseif op == "contains" then
    ---@cast value string
    return string_format("%s LIKE '%%%s%%'", key, value:gsub("'", "''"))
  elseif op == "startswith" then
    ---@cast value string
    return string_format("%s LIKE '%s%%'", key, value:gsub("'", "''"))
  elseif op == "endswith" then
    ---@cast value string
    return string_format("%s LIKE '%%%s'", key, value:gsub("'", "''"))
  elseif op == "null" then
    if value then
      return string_format("%s IS NULL", key)
    else
      return string_format("%s IS NOT NULL", key)
    end
  else
    error("invalid sql op: " .. tostring(op))
  end
end

---@param self Sql
---@return integer
function Sql._get_join_number(self)
  if self._join_keys then
    return nkeys(self._join_keys) + 1
  else
    return 1
  end
end

---@param self Sql
---@param where_token string
---@param tpl string
---@return Sql
function Sql._handle_where_token(self, where_token, tpl)
  if where_token == "" then
    return self
  elseif self._where == nil then
    self._where = where_token
  else
    self._where = string_format(tpl, self._where, where_token)
  end
  return self
end

---@param self Sql
---@param kwargs {[string|number]:any}
---@param logic? string
---@return string
function Sql._get_condition_token_from_table(self, kwargs, logic)
  local tokens = {}
  for k, value in pairs(kwargs) do
    if type(k) == "string" then
      tokens[#tokens + 1] = self:_get_expr_token(value, self:_get_where_key(k))
    else
      local token = self:_get_condition_token(value)
      if token ~= nil and token ~= "" then
        tokens[#tokens + 1] = '(' .. token .. ')'
      end
    end
  end
  if logic == nil then
    return table_concat(tokens, " AND ")
  else
    return table_concat(tokens, " " .. logic .. " ")
  end
end

---@param self Sql
---@param cond table|string|function
---@param op? DBValue
---@param dval? DBValue
---@return string
function Sql._get_condition_token(self, cond, op, dval)
  if op == nil then
    if type(cond) == 'table' then
      return Sql._get_condition_token_from_table(self, cond)
    else
      return Sql._base_get_condition_token(self, cond)
    end
  elseif dval == nil then
    ---@cast cond string
    return string_format("%s = %s", self:_get_column(cond), as_literal(op))
  else
    ---@cast cond string
    return string_format("%s %s %s", self:_get_column(cond), op, as_literal(dval))
  end
end

---@param self Sql
---@param cond table|string|function
---@param op? DBValue
---@param dval? DBValue
---@return string
function Sql._get_condition_token_or(self, cond, op, dval)
  if type(cond) == "table" then
    return self:_get_condition_token_from_table(cond, "OR")
  else
    return self:_get_condition_token(cond, op, dval)
  end
end

---@param self Sql
---@param cond table|string|function
---@param op? DBValue
---@param dval? DBValue
---@return string
function Sql._get_condition_token_not(self, cond, op, dval)
  local token
  if type(cond) == "table" then
    token = self:_get_condition_token_from_table(cond, "OR")
  else
    token = self:_get_condition_token(cond, op, dval)
  end
  return token ~= "" and string_format("NOT (%s)", token) or ""
end

---@param self Sql
---@param other_sql Sql
---@param set_operation_attr SqlSet
---@return Sql
function Sql._handle_set_option(self, other_sql, set_operation_attr)
  if not self[set_operation_attr] then
    self[set_operation_attr] = other_sql:statement();
  else
    self[set_operation_attr] = string_format("(%s) %s (%s)", self[set_operation_attr], PG_SET_MAP[set_operation_attr],
    other_sql:statement());
  end
  if self ~= Sql then
    self.statement = self._statement_for_set
  else
    error("don't call _handle_set_option directly on Sql class")
  end
  return self;
end

---@param self Sql
---@return string
function Sql._statement_for_set(self)
  local statement = Sql.statement(self)
  if self._intersect then
    statement = string_format("(%s) INTERSECT (%s)", statement, self._intersect)
  elseif self._intersect_all then
    statement = string_format("(%s) INTERSECT ALL (%s)", statement, self._intersect_all)
  elseif self._union then
    statement = string_format("(%s) UNION (%s)", statement, self._union)
  elseif self._union_all then
    statement = string_format("%s UNION ALL (%s)", statement, self._union_all)
  elseif self._except then
    statement = string_format("(%s) EXCEPT (%s)", statement, self._except)
  elseif self._except_all then
    statement = string_format("(%s) EXCEPT ALL (%s)", statement, self._except_all)
  end
  return statement
end

---@param self Sql
---@return string
function Sql.statement(self)
  local table_name = self:get_table()
  local statement = assemble_sql {
    table_name = table_name,
    with = self._with,
    join = self._join,
    distinct = self._distinct,
    returning = self._returning,
    insert = self._insert,
    update = self._update,
    delete = self._delete,
    using = self._using,
    select = self._select,
    from = self._from,
    where = self._where,
    group = self._group,
    having = self._having,
    order = self._order,
    limit = self._limit,
    offset = self._offset
  }
  return statement
end

---@param self Sql
---@param name string
---@param token? DBValue
---@return Sql
function Sql.with(self, name, token)
  local with_token = self:_get_with_token(name, token)
  if self._with then
    self._with = string_format("%s, %s", self._with, with_token)
  else
    self._with = with_token
  end
  return self
end

---@param self Sql
---@param other_sql Sql
---@return Sql
function Sql.union(self, other_sql)
  return self:_handle_set_option(other_sql, "_union");
end

---@param self Sql
---@param other_sql Sql
---@return Sql
function Sql.union_all(self, other_sql)
  return self:_handle_set_option(other_sql, "_union_all");
end

---@param self Sql
---@param other_sql Sql
---@return Sql
function Sql.except(self, other_sql)
  return self:_handle_set_option(other_sql, "_except");
end

---@param self Sql
---@param other_sql Sql
---@return Sql
function Sql.except_all(self, other_sql)
  return self:_handle_set_option(other_sql, "_except_all");
end

---@param self Sql
---@param other_sql Sql
---@return Sql
function Sql.intersect(self, other_sql)
  return self:_handle_set_option(other_sql, "_intersect");
end

---@param self Sql
---@param other_sql Sql
---@return Sql
function Sql.intersect_all(self, other_sql)
  return self:_handle_set_option(other_sql, "_intersect_all");
end

---@param self Sql
---@param table_alias string
---@return Sql
function Sql.as(self, table_alias)
  self._as = table_alias
  return self
end

---@param self Sql
---@param name string
---@param rows Record[]
---@return Sql
function Sql.with_values(self, name, rows)
  local columns = utils.get_keys(rows[1])
  rows, columns = self:_get_cte_values_literal(rows, columns, true)
  local cte_name = string_format("%s(%s)", name, table_concat(columns, ", "))
  local cte_values = string_format("(VALUES %s)", as_token(rows))
  return self:with(cte_name, cte_values)
end

---@param self Sql
---@param rows Records|Sql
---@param columns? string[]
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function Sql.insert(self, rows, columns)
  return Sql._base_insert(self, rows, columns)
end

---@param self Sql
---@param row Record|Sql|string
---@param columns? string[]
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function Sql.update(self, row, columns)
  if type(row) == 'string' then
    return Sql._base_update(self, row)
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
function Sql.merge(self, rows, key, columns)
  if #rows == 0 then
    error("empty rows passed to merge")
  end
  Sql._base_merge(self, rows, key, columns)
  return self
end

---@param self Sql
---@param rows Record[]
---@param key Keys
---@param columns? string[]
---@return Sql|XodelInstance[]
---@diagnostic disable-next-line: duplicate-set-field
function Sql.upsert(self, rows, key, columns)
  if #rows == 0 then
    error("empty rows passed to merge")
  end
  Sql._base_upsert(self, rows, key, columns)
  return self
end

---@param self Sql
---@param rows Record[]
---@param key Keys
---@param columns? string[]
---@return Sql|XodelInstance[]
---@diagnostic disable-next-line: duplicate-set-field
function Sql.updates(self, rows, key, columns)
  if #rows == 0 then
    error("empty rows passed to merge")
  end
  Sql._base_updates(self, rows, key, columns)
  return self
end

---@param self Sql
---@param rows Record[]
---@param key Keys
---@return Sql|XodelInstance[]
function Sql.get_merge(self, rows, key)
  local columns = utils.get_keys(rows[1])
  rows, columns = self:_get_cte_values_literal(rows, columns, true)
  local join_cond = self:_get_join_conditions(key, "V", self._as or self.table_name)
  local cte_name = string_format("V(%s)", table_concat(columns, ", "))
  local cte_values = string_format("(VALUES %s)", as_token(rows))
  Sql._base_select(self, "V.*"):with(cte_name, cte_values):_base_right_join("V", join_cond)
  return self
end

---@param self Sql
---@return Sql
function Sql.copy(self)
  local copy_sql = {}
  for key, value in pairs(self) do
    if type(value) == 'table' then
      copy_sql[key] = clone(value)
    else
      copy_sql[key] = value
    end
  end
  return setmetatable(copy_sql, getmetatable(self))
end

---@param self Sql
---@param cond? table|string|function
---@param op? string
---@param dval? DBValue
---@return Sql
function Sql.delete(self, cond, op, dval)
  self._delete = true
  if cond ~= nil then
    self:where(cond, op, dval)
  end
  return self
end

---@param self Sql
---@return Sql
function Sql.distinct(self)
  self._distinct = true
  return self
end

---@param self Sql
---@param a DBValue
---@param b? DBValue
---@param ...? DBValue
---@return Sql
function Sql.select(self, a, b, ...)
  local s = self:_get_select_token(a, b, ...)
  if not self._select then
    self._select = s
  elseif s ~= nil and s ~= "" then
    self._select = self._select .. ", " .. s
  end
  return self
end

---@param self Sql
---@param a DBValue
---@param b? DBValue
---@param ...? DBValue
---@return Sql
function Sql.select_literal(self, a, b, ...)
  local s = self:_get_select_token_literal(a, b, ...)
  if not self._select then
    self._select = s
  elseif s ~= nil and s ~= "" then
    self._select = self._select .. ", " .. s
  end
  return self
end

---@param self Sql
---@param a DBValue
---@param b? DBValue
---@param ...? DBValue
---@return Sql
function Sql.returning(self, a, b, ...)
  local s = self:_get_select_token(a, b, ...)
  if not self._returning then
    self._returning = s
  elseif s ~= nil and s ~= "" then
    self._returning = self._returning .. ", " .. s
  else
    return self
  end
  if self._returning_args then
    self._returning_args = { self._returning_args, a, b, ... }
  else
    self._returning_args = { a, b, ... }
  end
  return self
end

---@param self Sql
---@param a DBValue
---@param b? DBValue
---@param ...? DBValue
---@return Sql
function Sql.returning_literal(self, a, b, ...)
  local s = self:_get_select_token_literal(a, b, ...)
  if not self._returning then
    self._returning = s
  elseif s ~= nil and s ~= "" then
    self._returning = self._returning .. ", " .. s
  end
  --**this should be _returning_literal_args ?
  if self._returning_args then
    self._returning_args = { self._returning_args, a, b, ... }
  else
    self._returning_args = { a, b, ... }
  end
  return self
end

function Sql.group(self, ...)
  if not self._group then
    self._group = self:_get_select_token(...)
  else
    self._group = self._group .. ", " .. self:_get_select_token(...)
  end
  return self
end

function Sql.group_by(self, ...) return self:group(...) end

function Sql.order(self, ...)
  if not self._order then
    self._order = self:_get_select_token(...)
  else
    self._order = self._order .. ", " .. self:_get_select_token(...)
  end
  return self
end

function Sql.order_by(self, ...) return self:order(...) end

---@param self Sql
---@param a string
---@param ... string
---@return Sql
function Sql.using(self, a, ...)
  self._delete = true
  self._using = self:_get_select_token(a, ...)
  return self
end

---@param self Sql
---@param a string
---@param ... string
---@return Sql
function Sql.from(self, a, ...)
  if not self._from then
    self._from = self:_get_select_token(a, ...)
  else
    self._from = self._from .. ", " .. self:_get_select_token(a, ...)
  end
  return self
end

---@param self Sql
---@return string
function Sql.get_table(self)
  return (self._as == nil and self.table_name) or (self.table_name .. ' AS ' .. self._as)
end

---@param self Sql
---@param join_args string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function Sql.join(self, join_args, key, op, val)
  Sql._base_join(self, join_args, key, op, val)
  return self
end

---@param self Sql
---@param join_args string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function Sql.inner_join(self, join_args, key, op, val)
  Sql._base_join(self, join_args, key, op, val)
  return self
end

---@param self Sql
---@param join_args string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function Sql.left_join(self, join_args, key, op, val)
  Sql._base_left_join(self, join_args, key, op, val)
  return self
end

---@param self Sql
---@param join_args string
---@param key string
---@param op? string
---@param val? DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function Sql.right_join(self, join_args, key, op, val)
  Sql._base_right_join(self, join_args, key, op, val)
  return self
end

---@param self Sql
---@param join_args string
---@param key string
---@param op string
---@param val DBValue
---@return Sql
---@diagnostic disable-next-line: duplicate-set-field
function Sql.full_join(self, join_args, key, op, val)
  Sql._base_full_join(self, join_args, key, op, val)
  return self
end

---@param self Sql
---@param n integer
---@return Sql
function Sql.limit(self, n)
  self._limit = n
  return self
end

---@param self Sql
---@param n integer
---@return Sql
function Sql.offset(self, n)
  self._offset = n
  return self
end

---@param self Sql
---@param cond table|string|function
---@param op? string
---@param dval? DBValue
---@return Sql
function Sql.where(self, cond, op, dval)
  local where_token = self:_get_condition_token(cond, op, dval)
  return self:_handle_where_token(where_token, "(%s) AND (%s)")
end

---@param self Sql
---@param cond table|string|function
---@param op? string
---@param dval? DBValue
---@return Sql
function Sql.where_or(self, cond, op, dval)
  local where_token = self:_get_condition_token_or(cond, op, dval)
  return self:_handle_where_token(where_token, "(%s) AND (%s)")
end

---@param self Sql
---@param cond table|string|function
---@param op? string
---@param dval? DBValue
---@return Sql
function Sql.or_where_or(self, cond, op, dval)
  local where_token = self:_get_condition_token_or(cond, op, dval)
  return self:_handle_where_token(where_token, "%s OR %s")
end

---@param self Sql
---@param cond table|string|function
---@param op? string
---@param dval? DBValue
---@return Sql
function Sql.where_not(self, cond, op, dval)
  local where_token = self:_get_condition_token_not(cond, op, dval)
  return self:_handle_where_token(where_token, "(%s) AND (%s)")
end

---@param self Sql
---@param cond table|string|function
---@param op? string
---@param dval? DBValue
---@return Sql
function Sql.or_where(self, cond, op, dval)
  local where_token = self:_get_condition_token(cond, op, dval)
  return self:_handle_where_token(where_token, "%s OR %s")
end

---@param self Sql
---@param cond table|string|function
---@param op? string
---@param dval? DBValue
---@return Sql
function Sql.or_where_not(self, cond, op, dval)
  local where_token = self:_get_condition_token_not(cond, op, dval)
  return self:_handle_where_token(where_token, "%s OR %s")
end

---@param self Sql
---@param builder Sql|string
---@return Sql
function Sql.where_exists(self, builder)
  if self._where then
    self._where = string_format("(%s) AND EXISTS (%s)", self._where, builder)
  else
    self._where = string_format("EXISTS (%s)", builder)
  end
  return self
end

---@param self Sql
---@param builder Sql|string
---@return Sql
function Sql.where_not_exists(self, builder)
  if self._where then
    self._where = string_format("(%s) AND NOT EXISTS (%s)", self._where, builder)
  else
    self._where = string_format("NOT EXISTS (%s)", builder)
  end
  return self
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql.where_in(self, cols, range)
  if type(cols) == "string" then
    return Sql._base_where_in(self, self:_get_column(cols), range)
  else
    local res = {}
    for i = 1, #cols do
      res[i] = self:_get_column(cols[i])
    end
    return Sql._base_where_in(self, res, range)
  end
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql.where_not_in(self, cols, range)
  if type(cols) == "string" then
    cols = self:_get_column(cols)
  else
    for i = 1, #cols do
      cols[i] = self:_get_column(cols[i])
    end
  end
  return Sql._base_where_not_in(self, cols, range)
end

---@param self Sql
---@param col string
---@return Sql
function Sql.where_null(self, col)
  return Sql._base_where_null(self, self:_get_column(col))
end

---@param self Sql
---@param col string
---@return Sql
function Sql.where_not_null(self, col)
  return Sql._base_where_not_null(self, self:_get_column(col))
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql.where_between(self, col, low, high)
  return Sql._base_where_between(self, self:_get_column(col), low, high)
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql.where_not_between(self, col, low, high)
  return Sql._base_where_not_between(self, self:_get_column(col), low, high)
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql.or_where_in(self, cols, range)
  if type(cols) == "string" then
    cols = self:_get_column(cols)
  else
    for i = 1, #cols do
      cols[i] = self:_get_column(cols[i])
    end
  end
  return Sql._base_or_where_in(self, cols, range)
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql.or_where_not_in(self, cols, range)
  if type(cols) == "string" then
    cols = self:_get_column(cols)
  else
    for i = 1, #cols do
      cols[i] = self:_get_column(cols[i])
    end
  end
  return Sql._base_or_where_not_in(self, cols, range)
end

---@param self Sql
---@param col string
---@return Sql
function Sql.or_where_null(self, col)
  return Sql._base_or_where_null(self, self:_get_column(col))
end

---@param self Sql
---@param col string
---@return Sql
function Sql.or_where_not_null(self, col)
  return Sql._base_or_where_not_null(self, self:_get_column(col))
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql.or_where_between(self, col, low, high)
  return Sql._base_or_where_between(self, self:_get_column(col), low, high)
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql.or_where_not_between(self, col, low, high)
  return Sql._base_or_where_not_between(self, self:_get_column(col), low, high)
end

---@param self Sql
---@param builder Sql
---@return Sql
function Sql.or_where_exists(self, builder)
  if self._where then
    self._where = string_format("%s OR EXISTS (%s)", self._where, builder)
  else
    self._where = string_format("EXISTS (%s)", builder)
  end
  return self
end

---@param self Sql
---@param builder Sql
---@return Sql
function Sql.or_where_not_exists(self, builder)
  if self._where then
    self._where = string_format("%s OR NOT EXISTS (%s)", self._where, builder)
  else
    self._where = string_format("NOT EXISTS (%s)", builder)
  end
  return self
end

---@param self Sql
---@param cond table|string|function
---@param op? DBValue
---@param dval? DBValue
function Sql.having(self, cond, op, dval)
  if self._having then
    self._having = string_format("(%s) AND (%s)", self._having, self:_get_condition_token(cond, op, dval))
  else
    self._having = self:_get_condition_token(cond, op, dval)
  end
  return self
end

---@param self Sql
---@param cond table|string|function
---@param op? DBValue
---@param dval? DBValue
function Sql.having_not(self, cond, op, dval)
  if self._having then
    self._having = string_format("(%s) AND (%s)", self._having, self:_get_condition_token_not(cond, op, dval))
  else
    self._having = self:_get_condition_token_not(cond, op, dval)
  end
  return self
end

---@param self Sql
---@param builder Sql
---@return Sql
function Sql.having_exists(self, builder)
  if self._having then
    self._having = string_format("(%s) AND EXISTS (%s)", self._having, builder)
  else
    self._having = string_format("EXISTS (%s)", builder)
  end
  return self
end

---@param self Sql
---@param builder Sql
---@return Sql
function Sql.having_not_exists(self, builder)
  if self._having then
    self._having = string_format("(%s) AND NOT EXISTS (%s)", self._having, builder)
  else
    self._having = string_format("NOT EXISTS (%s)", builder)
  end
  return self
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql.having_in(self, cols, range)
  local in_token = self:_get_in_token(cols, range)
  if self._having then
    self._having = string_format("(%s) AND %s", self._having, in_token)
  else
    self._having = in_token
  end
  return self
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql.having_not_in(self, cols, range)
  local not_in_token = self:_get_in_token(cols, range, "NOT IN")
  if self._having then
    self._having = string_format("(%s) AND %s", self._having, not_in_token)
  else
    self._having = not_in_token
  end
  return self
end

---@param self Sql
---@param col string
---@return Sql
function Sql.having_null(self, col)
  if self._having then
    self._having = string_format("(%s) AND %s IS NULL", self._having, col)
  else
    self._having = col .. " IS NULL"
  end
  return self
end

---@param self Sql
---@param col string
---@return Sql
function Sql.having_not_null(self, col)
  if self._having then
    self._having = string_format("(%s) AND %s IS NOT NULL", self._having, col)
  else
    self._having = col .. " IS NOT NULL"
  end
  return self
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql.having_between(self, col, low, high)
  if self._having then
    self._having = string_format("(%s) AND (%s BETWEEN %s AND %s)", self._having, col, low, high)
  else
    self._having = string_format("%s BETWEEN %s AND %s", col, low, high)
  end
  return self
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql.having_not_between(self, col, low, high)
  if self._having then
    self._having = string_format("(%s) AND (%s NOT BETWEEN %s AND %s)", self._having, col, low, high)
  else
    self._having = string_format("%s NOT BETWEEN %s AND %s", col, low, high)
  end
  return self
end

---@param self Sql
---@param cond table|string|function
---@param op? DBValue
---@param dval? DBValue
function Sql.or_having(self, cond, op, dval)
  if self._having then
    self._having = string_format("%s OR %s", self._having, self:_get_condition_token(cond, op, dval))
  else
    self._having = self:_get_condition_token(cond, op, dval)
  end
  return self
end

---@param self Sql
---@param cond table|string|function
---@param op? DBValue
---@param dval? DBValue
function Sql.or_having_not(self, cond, op, dval)
  if self._having then
    self._having = string_format("%s OR %s", self._having, self:_get_condition_token_not(cond, op, dval))
  else
    self._having = self:_get_condition_token_not(cond, op, dval)
  end
  return self
end

---@param self Sql
---@param builder Sql
---@return Sql
function Sql.or_having_exists(self, builder)
  if self._having then
    self._having = string_format("%s OR EXISTS (%s)", self._having, builder)
  else
    self._having = string_format("EXISTS (%s)", builder)
  end
  return self
end

---@param self Sql
---@param builder Sql
---@return Sql
function Sql.or_having_not_exists(self, builder)
  if self._having then
    self._having = string_format("%s OR NOT EXISTS (%s)", self._having, builder)
  else
    self._having = string_format("NOT EXISTS (%s)", builder)
  end
  return self
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql.or_having_in(self, cols, range)
  local in_token = self:_get_in_token(cols, range)
  if self._having then
    self._having = string_format("%s OR %s", self._having, in_token)
  else
    self._having = in_token
  end
  return self
end

---@param self Sql
---@param cols string|string[]
---@param range Sql|table|string
---@return Sql
function Sql.or_having_not_in(self, cols, range)
  local not_in_token = self:_get_in_token(cols, range, "NOT IN")
  if self._having then
    self._having = string_format("%s OR %s", self._having, not_in_token)
  else
    self._having = not_in_token
  end
  return self
end

---@param self Sql
---@param col string
---@return Sql
function Sql.or_having_null(self, col)
  if self._having then
    self._having = string_format("%s OR %s IS NULL", self._having, col)
  else
    self._having = col .. " IS NULL"
  end
  return self
end

---@param self Sql
---@param col string
---@return Sql
function Sql.or_having_not_null(self, col)
  if self._having then
    self._having = string_format("%s OR %s IS NOT NULL", self._having, col)
  else
    self._having = col .. " IS NOT NULL"
  end
  return self
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql.or_having_between(self, col, low, high)
  if self._having then
    self._having = string_format("%s OR (%s BETWEEN %s AND %s)", self._having, col, low, high)
  else
    self._having = string_format("%s BETWEEN %s AND %s", col, low, high)
  end
  return self
end

---@param self Sql
---@param col string
---@param low number
---@param high number
---@return Sql
function Sql.or_having_not_between(self, col, low, high)
  if self._having then
    self._having = string_format("%s OR (%s NOT BETWEEN %s AND %s)", self._having, col, low, high)
  else
    self._having = string_format("%s NOT BETWEEN %s AND %s", col, low, high)
  end
  return self
end

return Sql
