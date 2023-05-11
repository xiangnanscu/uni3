local migrate = require "xodel.migrate"
local utils = require("xodel.utils")
local Model = require("xodel.model")


local db_options = {
  DATABASE = 'test'
}

local Usr = Model:create_model {
  db_options = db_options,
  table_name = 'usr',
  fields = {
    { name = 'id',    type = 'integer', primary_key = true, serial = true },
    { name = 'email', type = 'string',  unique = true,      maxlength = 20 },
    { name = 'views', type = 'integer', default = 0 },
    { name = 'name',  maxlength = 10,   default = 'foo' }
  }
}

local Profile = Model:create_model {
  db_options = db_options,
  table_name = 'profile',
  fields = {
    { name = 'sex',    required = false, choices = { 'f', 'm' }, default = 'f' },
    { name = 'usr_id', reference = Usr,  reference_column = 'id' }
  }
}

local Post = Model:mix_with_base {
  db_options = db_options,
  table_name = 'post',
  field_names = { 'title', 'content', 'published', 'author_id' },
  fields = {
    { name = 'title',     maxlength = 10 },
    { name = 'content',   maxlength = 100,  required = false },
    { name = 'published', type = 'boolean', default = false },
    { name = 'author_id', reference = Usr,  reference_column = 'id' }
  }
}

local Log = Model:create_model {
  db_options = db_options,
  table_name = 'log',
  fields = {
    { name = 'id',         type = 'integer', primary_key = true, serial = true },
    { name = 'delete_id',  type = 'integer', default = 0 },
    { name = 'model_name', type = 'string',  maxlength = 20 },
    { name = 'action',     maxlength = 10, }
  }
}
local models = {
  Usr,
  Profile,
  Post,
  Log
}

local function crate_table_from_models()
  local res = {}
  for i = #models, 1, -1 do
    local model = models[i]
    assert(Usr:query("DROP TABLE IF EXISTS " .. model.table_name))
  end
  for _, model in ipairs(models) do
    assert(Usr:query(migrate.get_table_defination(model)))
    res[model.table_name] = model
  end
  return res
end

return crate_table_from_models
