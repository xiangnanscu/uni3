local pgmoon        = require "pgmoon"
local utils         = require "xodel.utils"
local type          = type
local table_concat  = table.concat
local string_format = string.format
local os            = os
-- local version = "2.2"

---@class QueryOpts
---@field HOST string
---@field PORT number
---@field USER string
---@field DATABASE string
---@field PASSWORD string
---@field POOL_SIZE number
---@field CONNECT_TIMEOUT number
---@field MAX_IDLE_TIMEOUT number
---@field SSL boolean
---@field POOL string
---@field SSL_REQUIRED boolean
---@field SSL_VERIFY any
---@field getenv fun(key:string):any

---comment
---@param options QueryOpts
---@return table
local function get_connect_table(options)
  local env = options.getenv or os.getenv
  return {
    host = options.HOST or env "PGHOST" or "127.0.0.1",
    port = options.PORT or env "PGPORT" or 5432,
    database = options.DATABASE or env "PGDATABASE" or "postgres",
    user = options.USER or env "PGUSER" or "postgres",
    password = options.PASSWORD or env "PGPASSWORD" or "postgres",
    ssl = options.SSL or env "PG_SSL" or false,
    ssl_verify = options.SSL_VERIFY or env "PG_SSL_VERIFY" or nil,
    ssl_required = options.SSL_REQUIRED or env "PG_SSL_REQUIRED" or nil,
    pool = options.POOL or env "PG_POOL" or nil,
    pool_size = options.POOL_SIZE or env "PG_POOL_SIZE" or 100,
    connect_timeout = options.CONNECT_TIMEOUT or env "PG_CONNECT_TIMEOUT" or 1000,
    max_idle_timeout = options.MAX_IDLE_TIMEOUT or env "PG_MAX_IDLE_TIMEOUT" or 10000,
  }
end

-- local LOG_STATEMENT = io.open('QUERY_STATEMENT'):read("a")


---@param options QueryOpts
---@return fun(statement: string|table, compact?: boolean):table?, string|number?
local function Query(options)
  options = options or {}
  local db_connect_table = get_connect_table(options)
  -- require("xodel.utils").loger(db_connect_table)
  local connect_timeout = db_connect_table.connect_timeout
  local max_idle_timeout = db_connect_table.max_idle_timeout
  local pool_size = db_connect_table.pool_size
  ---@param statement string|table
  ---@param compact? boolean
  ---@return table?, string|number?
  local function sql_query(statement, compact)
    local db, ok, err, a, b
    if type(statement) == 'table' then
      if type(statement.statement) == 'function' then
        statement, err = statement:statement()
        if statement == nil then
          return nil, err
        end
      elseif statement[1] then
        local statements = {}
        for _, query in ipairs(statement) do
          if type(query) == 'string' then
            if query ~= "" then
              statements[#statements + 1] = query
            end
          elseif type(query) == 'table' and type(query.statement) == 'function' then
            local substatement, err = query:statement()
            if substatement == nil then
              return nil, err
            end
            statements[#statements + 1] = substatement
          else
            return nil, string_format("invalid type '%s' for statements passing to query", type(query))
          end
        end
        statement = table_concat(statements, ";")
      else
        return nil, "empty table passed to query"
      end
    end
    db = pgmoon.new(db_connect_table)
    db:settimeout(connect_timeout)
    ok, err = db:connect()
    if not ok then
      return nil, err
    end
    -- https://github.com/leafo/pgmoon/blob/master/pgmoon/init.lua#L545
    -- nil,  err_msg,   result,     num_queries, notifications
    -- result, num_queries, notifications
    db.compact = compact
    a, b = db:query(statement)
    if utils.getenv("DEBUG_SQL") == 'on' then
      utils.loger_sql(statement)
    end
    if db.sock_type == "nginx" then
      if a ~= nil then
        ok, err = db:keepalive(max_idle_timeout, pool_size)
        if not ok then
          return nil, "fail to keepalive:" .. err
        else
          return a, b
        end
      else
        return nil, b
      end
    else
      if a == nil then
        return nil, b
      else
        ok, err = db:disconnect()
        if not ok then
          return nil, "fail to disconnect:" .. err
        else
          return a, b
        end
      end
    end
  end

  return sql_query
end

return Query
