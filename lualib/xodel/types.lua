--@diagnostic disable: duplicate-set-field
---@meta

---@alias Keys string|string[]
---@alias SqlSet "_union"|"_union_all"| "_except"| "_except_all"|"_intersect"|"_intersect_all"
---@alias Token fun(): string
---@alias DBLoadValue string|number|boolean|table
---@alias DBValue DBLoadValue|Token
---@alias CteRetOpts {columns: string[], literals: DBValue[], literal_columns: string[]}
---@alias SqlOptions {table_name:string,delete?:boolean,distinct?:boolean,from?:string,group?:string,having?:string,insert?:string,limit?:number,offset?:number,order?:string,select?:string,update?:string,using?:string,where?:string,with?:string,returning?: string}
---@alias Record {[string]:DBValue}
---@alias Records Record|Record[]
---@alias ValidateErrorObject {[string]: any}
---@alias ValidateError string|ValidateErrorObject
---@alias JOIN_TYPE "INNER"|"LEFT"|"RIGHT"|"FULL"

---@param self table
function table.clear(self)
end

---@param narray? integer
---@param nhash? integer
---@return table
function table.new(narray, nhash)
end

---@class Array<T>: { [integer]: T }
local Array = {}

---@param cls Array
---@param self? table
---@return Array
function Array.new(cls, self)
end

---@param self Array
---@param ... table
function Array.concat(self, ...)
end

---@param self Array
---@return Array
function Array.entries(self)
end

---@param self Array
---@param callback function
---@return boolean
function Array.every(self, callback)
end

---@param self Array
---@param v any
---@param s? number
---@param e? number
---@return Array
function Array.fill(self, v, s, e)
end

---@param self Array
---@param callback function
---@return Array
function Array.filter(self, callback)
end

---@param self Array
---@param callback function
---@return any
function Array.find(self, callback)
end

---@param self Array
---@param callback function
---@return integer
function Array.find_index(self, callback)
end

Array.findIndex = Array.find_index

---@param self Array
---@param depth? integer
---@return Array
function Array.flat(self, depth)
end

---@param self Array
---@param callback function
---@return Array
function Array.flat_map(self, callback)
end

Array.flatMap = Array.flat_map

---@param self Array
---@param callback function
function Array.for_each(self, callback)
end

Array.forEach = Array.for_each

---@param self Array
---@param callback function
---@return table
function Array.group_by(self, callback)
end

---@param self Array
---@param value any
---@param s? integer
---@return boolean
function Array.includes(self, value, s)
end

---@param self Array
---@param value any
---@param s? integer
---@return integer
function Array.index_of(self, value, s)
end

Array.indexOf = Array.index_of

---@param self Array
---@param sep? string
---@return string
function Array.join(self, sep)
end

---@param self Array
---@return Array
function Array.keys(self)
end

---@param self Array
---@param value any
---@param s? integer
---@return integer
function Array.last_index_of(self, value, s)
end

Array.lastIndexOf = Array.last_index_of

---@param self Array
---@param callback function
---@return Array
function Array.map(self, callback)
end

---@param self Array
---@return any
function Array.pop(self)
end

---@param self Array
---@param ... any
---@return integer
function Array.push(self, ...)
end

---@param self Array
---@param callback function
---@param init any
---@return any
function Array.reduce(self, callback, init)
end

---@param self Array
---@param callback function
---@param init any
---@return any
function Array.reduce_right(self, callback, init)
end

Array.reduceRright = Array.reduce_right

---@param self Array
---@return Array
function Array.reverse(self)
end

---@param self Array
---@return unknown
function Array.shift(self)
end

---@param self Array
---@param s? integer
---@param e? integer
---@return Array
function Array.slice(self, s, e)
end

---@param self Array
---@param callback function
---@return boolean
function Array.some(self, callback)
end

---@param self Array
---@param callback function
---@return Array
function Array.sort(self, callback)
end

---@param self Array
---@param s? integer
---@param del_cnt? integer
---@param ... any
---@return Array
function Array.splice(self, s, del_cnt, ...)
end

---@param self Array
---@param ... any
---@return integer
function Array.unshift(self, ...)
end

---@param self Array
---@return Array
function Array.values(self)
end

-- other methods

---@param self Array
---@param key string
---@return table
function Array.group_by_key(self, key)
end

---@param self Array
---@param key string
---@return Array
function Array.map_key(self, key)
end

Array.sub = Array.slice

---@param self Array
function Array.clear(self)
end

---@param self Array
---@return any
function Array.dup(self)
  local already = {}
  for i = 1, #self do
    local e = self[i]
    if already[e] then
      return e
    else
      already[e] = true
    end
  end
end

Array.duplicate = Array.dup

local FIRST_DUP_ADDED = {}

---@param self Array
---@return Array
function Array.dups(self)
end

---@param self Array
---@param callback function
---@return any
function Array.dup_map(self, callback)
end

---@param self Array
---@param callback function
---@return Array
function Array.dups_map(self, callback)
end

---@param self Array
---@return Array
function Array.uniq(self)
end

---@param self Array
---@param callback function
---@return Array
function Array.uniq_map(self, callback)
end

---@param self Array
---@return Set
function Array.as_set(self)
end

---@param self Array
---@param o any
---@return boolean
function Array.equals(self, o)
end

Array.__eq = Array.equals

---@param self Array
---@param o Array
function Array.__add(self, o)
end

---@param self Array
---@param o Array
function Array.__sub(self, o)
end

---@param self Array
---@param callback function
---@return Array
function Array.exclude(self, callback)
end

---@param self Array
---@param callback function
---@return integer
function Array.count(self, callback)
end

---@param self Array
---@param callback function
---@return integer
function Array.count_exclude(self, callback)
end

---@param self Array
---@param n integer
---@return Array
function Array.combine(self, n)
end

---@class Field
---@field __is_field_class__ boolean
---@field NOT_DEFIEND table
---@field type string
---@field option_names string[]
---@field required boolean
---@field label string
---@field choices Array
---@field strict boolean
---@field error_messages table
---@field default any
---@field hint string
---@field tag string
---@field choices_module_name string
---@field columns Array
---@field verify_url string
---@field post_names string[]
---@field code_lifetime number
---@field primary_key string
---@field null boolean
---@field unique boolean
---@field index boolean
---@field db_type string
---@field compact boolean
---@field trim boolean
---@field pattern string
---@field length integer
---@field minlength integer
---@field maxlength integer
---@field sfzh boolean
---@field min number
---@field max number
---@field serial boolean
---@field precision integer
---@field cn boolean
---@field model Xodel
---@field max_rows integer
---@field uploadable boolean
---@field auto_now_add boolean
---@field auto_now boolean
---@field timezone boolean
---@field reference Xodel|string
---@field reference_column string
---@field realtime boolean
---@field autocomplete boolean
---@field url string
---@field keywordQueryName string
---@field limitQueryName string
local Field = {}

---@param cls Field
---@param options table
---@return Field
function Field.new(cls, options)
end

---@param self Field
---@param options table
---@return Field
function Field.constructor(self, options)
end

---@param self Field
---@return string[]
function Field.get_option_names(self)
end

---@param self Field
---@param options? table
---@return {[string]:any}
function Field.get_options(self, options)
end

---@param self Field
---@param validators function[]
---@return function[]
function Field.get_validators(self, validators)
end

---@param self Field
---@return {[string]:any}
function Field.json(self)
end

---@param self Field
---@param extra_attrs? {[string]:any}
---@return {[string]:any}
function Field.widget_attrs(self, extra_attrs)
end

---@param self Field
---@param value DBValue
---@param ctx Record
---@return DBValue
function Field.validate(self, value, ctx)
end

---@param self Field
---@param ctx Record
---@return any
function Field.get_default(self, ctx)
end

---@param self Field
---@param value DBValue
---@param data Record
---@return DBValue
function Field.prepare_for_db(self, value, data)
end

---@param self Field
---@param value DBValue
---@return DBValue
function Field.load(self, value)
end

---@param self Field
---@param value table
---@return Field
function Field.class(self, value)
end

---@class ModelClass
---@field __index ModelClass
---@field __is_model_class__? boolean
---@field instance_meta table
---@field table_name string
---@field auto_now_name? string
---@field disable_auto_primary_key? boolean
---@field primary_key string
---@field default_primary_key? string
---@field name_cache {[string]:string}
---@field name_to_label {[string]:string}
---@field label_to_name {[string]:string}
---@field fields {[string]:table}
---@field field_names string[]
---@field names Array
---@field mixins? table[]
---@field abstract? boolean
---@field foreign_keys {[string]:table}
local ModelClass = {}

---@class XodelInstance
---@field __index XodelInstance
local XodelInstance = {}

---@param self XodelInstance
---@param key? string
function XodelInstance.delete(self, key)
end

---@param self XodelInstance
---@param names? string[]
---@param key? string
---@return XodelInstance
function XodelInstance.save(self, names, key)
end

---@param self XodelInstance
---@param names? string[]
---@param key? string
---@return XodelInstance
function XodelInstance.save_create(self, names, key)
end

---@param self XodelInstance
---@param names? string[]
---@param key? string
---@return XodelInstance
function XodelInstance.save_update(self, names, key)
end

---@param self XodelInstance
---@param names? string[]
---@param key? string
---@return Record?
---@return table|string?
function XodelInstance.validate(self, names, key)
end

---@param self XodelInstance
---@param names? string[]
---@return Record?
---@return table|string?
function XodelInstance.validate_update(self, names)
end

---@param self XodelInstance
---@param names? string[]
---@return Record?
---@return table|string?
function XodelInstance.validate_create(self, names)
end
