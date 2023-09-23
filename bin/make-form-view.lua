local utils = require "xodel.utils"
local xodel_init = require "xodel.init"
local template = require("resty.template")
local Array = require "xodel.array"
local Object = require "xodel.object"
local prettycjson = require "resty.prettycjson"
local format = string.format
-- local forms = require "forms"

local function prefix(str)
  return function(e)
    return e:sub(1, #str) == str
  end
end

local function capitalize(model_name)
  return model_name:sub(1, 1):upper() .. model_name:sub(2)
end

local function render_template(opts)
  local content = template.new(opts.template_file):process(opts.context)
  local f = assert(io.open(opts.output_file, "w"))
  f:write(content)
  f:close()
end

if select('#', ...) ~= 0 then
  return
end

if #arg == 0 then
  error("no args provided")
  return
end
local init = xodel_init()
local args = Array(arg)
local model_name
local model_arg = args:find(prefix('-model='))
if model_arg then
  model_name = utils.snake_to_camel(model_arg:sub(#'-model=' + 1))
else
  model_name = utils.snake_to_camel(args[#args])
end

local admin_mode = false
if args:find(prefix('-admin')) then
  admin_mode = true
end

local base_views = 'auto_generated'

local dir
local dir_arg = args:find(prefix('-dir='))
if dir_arg then
  dir = dir_arg:sub(#'-dir=' + 1)
elseif admin_mode then
  dir = 'Admin'
else
  dir = ''
end
local views_dir_path = format('%s/%s', base_views, dir)
if not utils.dir_exists(views_dir_path) then
  utils.mkdirs(views_dir_path)
end
local component_name = capitalize(model_name)
local form_route_name = component_name
local table_name = utils.camel_to_snake(model_name)

local model = init.models[table_name]
if not model then
  error("invalid model name: " .. table_name)
end
local fk_import_statement = ""
local function strip_model_json(json)
  local defaults = {
    tag = 'input',
    default = "",
    lazy = true,
    required = false,
    trim = true,
    compact = true,
    type = 'string',
    upload_url = "//lzwlkj.oss-cn-shenzhen.aliyuncs.com/"
  }
  local fields = {}
  for key, field in pairs(json.fields) do
    local f = {}
    for fk, fv in pairs(field) do
      if defaults[fk] ~= fv then
        f[fk] = fv
      end
    end
    f.null = nil
    f.db_type = nil
    fields[key] = f
  end
  json.fields = fields
end
local model_json = model:to_json()
strip_model_json(model_json)
local not_display_types = {
  text = true,
  json = true,
  table = true,
  array = true,
  alioss_list = true,
  alioss_image_list = true
}
local function is_list_field(f)
  if not_display_types[f.type] then
    return false
  end
  return true
end
local model_fields = model.names:map(function(e) return model_json.fields[e] end)
local field_names_token = model.names:map(function(e) return format('"%s"', e) end):join(", ")
local list_names_token = model.names
    :map(function(e) return model.fields[e] end)
    :filter(is_list_field)
    :map(function(f) return format('"%s"', f.name) end)
    :join(", ")
fk_import_statement = model.names:map(function(e) return model.fields[e] end):filter(function(f)
      return f.reference
    end)
    :map(function(f)
      local fk_model = utils.to_model_name(f.reference.table_name)
      return format([[local %s = require("models").%s]], fk_model, fk_model)
    end):join("\n")
local form_instance_token = model_fields:map(function(f)
  return format([[values.%s = %sData.%s;]], f.name, table_name, f.name)
end):join("\n")
local form_field_token = Array()
local antdDataCallback = false
local unique_key
for i, field in ipairs(model_fields) do
  local name = field.name
  local label = field.label
  local hint = field.hint
  if field.unique and not unique_key then
    unique_key = field.name
  end
  if field.type ~= 'array' then
    form_field_token:push(format([[
      <a-form-item name="%s" label="%s"%s>
  %%s
      </a-form-item>]], name, label, hint and format([[ extra="%s"]], hint) or ""))
  else
    form_field_token:push(format([[
      <a-form-item
        v-for="(value, index) in values.%s"
        :key="index"
        v-bind="index === 0 ? {} : buttonItemLayout"
        :name="['%s', index]"
        :label="index === 0 ? '%s' : ''"%s
      >
  %%s
      </a-form-item>
      <a-form-item v-bind="values.%s.length === 0 ? { label: '%s'} : buttonItemLayout">
        <a-button type="dashed" @click="values.%s.push('')" class="array-field-width">
          <PlusOutlined />
          添加
        </a-button>
      </a-form-item>

      ]], name, name, label, hint and format([[ extra="%s"]], hint) or "", name, label, name))
  end

  if field.autocomplete or field.choices_url then
    form_field_token:push(format([[
      <a-auto-complete
        v-model:value="values.%s"
        :options="fields.%s.searchOptions"
        @keydown="(e) => e.keyCode === 13 && e.preventDefault()"
        @search="(text) => {
          if (!text) {
            return [];
          }
          const matchRule = new RegExp(text.split(``).join(`.*`));
          fields.%s.searchOptions = fields.%s.choices.filter((e) => {
            return e.value.includes(text) || matchRule.test(e.value);
          });
        }"
      >
        <template #option="{ label, hint }">
          <div style="display: flex; justify-content: space-between">
            {{label}}
            <span>{{hint}}</span>
          </div>
        </template>
      </a-auto-complete>
    ]], name, name, name, name, name))
  elseif field.choices then
    if field.tag == 'select' then
      form_field_token:push(format([[
      <a-select v-model:value="values.%s">
        <a-select-option v-for="(c, i) in fields.%s.choices" :key="i" :value="c.value">{{c.label}}</a-select-option>
      </a-select>
      ]], name, name, name))
    else
      form_field_token:push(format([[
      <a-radio-group v-model:value="values.%s">
        <a-radio-button v-for="(c, i) in fields.%s.choices" :key="i" :value="c.value">{{c.label}}</a-radio-button>
      </a-radio-group>
      ]], name, name))
    end
  elseif field.type == 'array' then
    form_field_token:push(format([[
      <a-input
        class="array-field-width"
        style="margin-right: 8px"
        v-model:value="values.%s[index]"
      />
      <MinusCircleOutlined
        v-if="values.%s.length > 0"
        class="dynamic-delete-button"
        @click="values.%s.splice(index, 1)"
      />
    ]], name, name, name))
  elseif field.type == 'alioss_image' then
    antdDataCallback = true
    form_field_token:push(format([[
      <a-upload
        v-model:fileList="values.%s"
        :data="Alioss.antdDataCallback"
        :action="fields.%s.upload_url || process.env.ALIOSS_URL"
        :multiple="false"
        :max-count="1"
        list-type="picture-card"
      >
        <div>
          <PlusOutlined />
          <div>{{ fields.%s.attrs?.button_text || "上传图片" }}</div>
        </div>
      </a-upload>]], name, name, name))
  elseif field.type == 'alioss_image_list' then
    antdDataCallback = true
    form_field_token:push(format([[
      <a-upload
        v-model:fileList="values.%s"
        :data="Alioss.antdDataCallback"
        :action="fields.%s.upload_url || process.env.ALIOSS_URL"
        :multiple="true"
        list-type="picture-card"
      >
        <div>
          <PlusOutlined />
          <div>{{ fields.%s.attrs?.button_text || "上传图片" }}</div>
        </div>
      </a-upload>
    ]], name, name, name))
  elseif field.type == 'alioss' then
    antdDataCallback = true
    form_field_token:push(format([[
      <a-upload
        v-model:fileList="values.%s"
        :data="Alioss.antdDataCallback"
        :action="fields.%s.upload_url || process.env.ALIOSS_URL"
        :multiple="false"
      >
        <a-button>
          <UploadOutlined></UploadOutlined>
          {{ fields.%s.attrs?.button_text || "上传文件" }}
        </a-button>
      </a-upload>
    ]], name, name, name))
  elseif field.type == 'alioss_list' then
    antdDataCallback = true
    form_field_token:push(format([[
      <a-upload
        v-model:fileList="values.%s"
        :data="Alioss.antdDataCallback"
        :action="fields.%s.upload_url || process.env.ALIOSS_URL"
        :multiple="true"
      >
        <a-button>
          <UploadOutlined></UploadOutlined>
          {{ fields.%s.attrs?.button_text || "上传文件" }}
        </a-button>
      </a-upload>
    ]], name, name, name))
  elseif field.type == 'date' then
    form_field_token:push(format([[
      <a-date-picker
        v-model:value="values.%s"
        value-format="fields.%s.attrs?.value_format || `YYYY-MM-DD`"
      />
    ]], name, name))
  elseif field.type == 'datetime' then
    form_field_token:push(format([[
      <a-date-picker
        :show-time="{ format: fields.%s.attrs?.time_format || `HH:mm` }"
        @change="(date, datetime)=>{values.%s=datetime}"
        value-format="fields.%s.attrs?.value_format || `YYYY-MM-DD`"
      />
    ]], name, name, name))
  elseif field.type == 'year' then
    form_field_token:push(format([[
      <a-date-picker
        v-model:value="values.%s"
        format="YYYY"
        value-format="YYYY"
        picker="year"
      />
    ]], name))
  elseif field.type == 'password' then
    form_field_token:push(format([[
      <a-input-password
        v-model:value="values.%s"
      ></a-input-password>]], name, name))
  elseif field.type == 'float' or field.type == 'integer' then
    form_field_token:push(format([[
      <a-input-number v-model:value="values.%s"></a-input-number>]], name, name))
  else
    form_field_token:push(format([[
      <a-input v-model:value="values.%s"></a-input>]], name, name))
  end
end
if not unique_key then
  unique_key = 'id'
end
local context = {
  model = model,
  form_route_name = form_route_name,
  model_token = prettycjson(model_json):gsub([[\/]], '/'):gsub('\t', '  '),
  model_pk = model.primary_key,
  auto_now_add_name = model.auto_now_add_name,
  model_name = model_name,
  table_name = table_name,
  component_name = component_name,
  model_name_prefix = model_name,
  unique_key = unique_key,
  field_names_token = field_names_token,
  list_names_token = list_names_token,
  fk_import_statement = fk_import_statement,
  form_field_token = utils.chunk(form_field_token, 2):map(function(e)
    local form_item_token, widget = e[1], e[2]
    return format(form_item_token, widget)
  end):join('\n'),
  form_instance_token = form_instance_token,
}
local nargs = #args
if args:find(prefix('-c')) or args:find(prefix('-all')) then
  render_template {
    context = context,
    template_file = './bin/template/controller.lua.txt',
    -- output_file = format('controllers/%s.lua', table_name),
    output_file = format('%s/%s/%s.lua', base_views, dir, table_name),
  }
end
if args:find(prefix('-f')) or args:find(prefix('-all')) then
  render_template {
    context = context,
    template_file = './bin/template/ModelForm.vue.txt',
    output_file = format('%s/%s/%sForm.vue', base_views, dir, component_name),
  }
end
if args:find(prefix('-l')) or args:find(prefix('-all')) then
  render_template {
    context = context,
    template_file = './bin/template/List.vue.txt',
    output_file = format('%s/%s/%sList.vue', base_views, dir, component_name),
  }
end
