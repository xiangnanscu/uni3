// get_options 和后端不同, attrs必存在
import {
  clone,
  assert,
  NULL,
  FK_TYPE_NOT_DEFIEND,
  get_localtime,
  parse_size,
} from "./utils.mjs";
import * as Validators from "./validator.mjs";
import { Model } from "./model.mjs";

const TABLE_MAX_ROWS = 1;
const CHOICES_ERROR_DISPLAY_COUNT = 30;
const DEFAULT_ERROR_MESSAGES = { required: "此项必填", choices: "无效选项" };
const PRIMITIVE_TYPES = {
  string: true,
  number: true,
  boolean: true,
  bigint: true,
};

function clean_choice(c) {
  let v;
  if (c.value !== undefined) {
    v = c.value;
  } else {
    v = c[0];
  }
  assert(v !== undefined, "you must provide a value for a choice");
  let l;
  if (c.label !== undefined) {
    l = c.label;
  } else if (c[1] !== undefined) {
    l = c[1];
  } else {
    l = v;
  }
  return [v, l, c.hint || c[2]];
}
function string_choices_to_array(s) {
  const choices = [];
  for (let line of s.split("\n")) {
    line = line.trim();
    if (line !== "") {
      choices.push(line);
    }
  }
  return choices;
}
function get_choices(raw_choices) {
  if (typeof raw_choices === "string") {
    raw_choices = string_choices_to_array(raw_choices);
  }
  if (!Array.isArray(raw_choices)) {
    throw new Error(`choices type must be table ,not ${typeof raw_choices}`);
  }
  const choices = [];
  for (let c of raw_choices) {
    if (typeof c === "string") {
      c = { value: c, label: c };
    } else if (PRIMITIVE_TYPES[typeof c]) {
      c = { value: c, label: String(c) };
    } else if (typeof c === "object") {
      const [value, label, hint] = clean_choice(c);
      c = { value, label, hint };
    } else {
      throw new Error("invalid choice type:" + typeof c);
    }
    choices.push(c);
  }
  return choices;
}
function serialize_choice(choice) {
  return String(choice.value);
}
function get_choices_error_message(choices) {
  const valid_choices = choices.map(serialize_choice).join("，");
  return `限下列选项：${valid_choices}`;
}
function get_choices_validator(choices, message) {
  if (choices.length <= CHOICES_ERROR_DISPLAY_COUNT) {
    message = `${message}，${get_choices_error_message(choices)}`;
  }
  const is_choice = {};
  for (const c of choices) {
    is_choice[c.value] = true;
  }
  function choices_validator(value) {
    if (!is_choice[value]) {
      throw new Error(message);
    } else {
      return value;
    }
  }
  return choices_validator;
}
const base_option_names = [
  "primary_key",
  "null",
  "unique",
  "index",
  "db_type",
  "required",
  "disabled",
  "default",
  "label",
  "hint",
  "error_messages",
  "choices",
  "strict",
  "choices_url",
  "choices_url_admin",
  "choices_url_method",
  "autocomplete",
  "preload",
  "lazy",
  "tag",
  "attrs",
];
class basefield {
  static option_names = [];
  static __is_field_class__ = true;
  static get_choices = get_choices;
  static create_field(options) {
    const self = new this(options);
    self.validators = self.get_validators([]);
    return self;
  }
  constructor(options) {
    this.name = assert(options.name, "you must define a name for a field");
    this.type = options.type || this.constructor.name;
    for (const name of this.get_option_names()) {
      if (options[name] !== undefined) {
        this[name] = options[name];
      }
    }
    if (options.attrs) {
      this.attrs = clone(options.attrs);
    } else {
      this.attrs = {};
    }
    if (this.required === undefined) {
      this.required = false;
    }
    if (this.db_type === undefined) {
      this.db_type = this.type;
    }
    if (this.label === undefined) {
      this.label = this.name;
    }
    if (this.null === undefined) {
      if (this.required || this.db_type === "varchar" || this.db_type === "text") {
        this.null = false;
      } else {
        this.null = true;
      }
    }
    if (Array.isArray(this.choices) || typeof this.choices === "string") {
      this.choices = get_choices(this.choices);
    }
    return this;
  }
  get_option_names() {
    return [...base_option_names, ...this.constructor.option_names];
  }
  get_error_message(key) {
    if (this.error_messages && this.error_messages[key]) {
      return this.error_messages[key];
    }
    return DEFAULT_ERROR_MESSAGES[key];
  }
  get_validators(validators) {
    if (this.required) {
      validators.unshift(Validators.required(this.get_error_message("required")));
    } else {
      validators.unshift(Validators.not_required);
    }
    // if (typeof this.choices_url === "string" && this.strict) {
    //   const dynamic_choices_validator = async (val) => {
    //     // console.log("call dd dynamic_choices_validator");
    //     let message = this.get_error_message("choices");
    //     const data = await basefield.Http[this.choices_url_method || "get"](
    //       this.choices_url,
    //     ).data;
    //     const choices = get_choices(data);
    //     for (const c of choices) {
    //       if (val === c.value) {
    //         return val;
    //       }
    //     }
    //     if (choices.length <= CHOICES_ERROR_DISPLAY_COUNT) {
    //       message = `${message}，${get_choices_error_message(choices)}`;
    //     }
    //     throw new Error(message);
    //   };
    //   validators.push(dynamic_choices_validator);
    // }
    if (
      Array.isArray(this.choices) &&
      this.choices.length &&
      (this.strict === undefined || this.strict)
    ) {
      validators.push(
        get_choices_validator(this.choices, this.get_error_message("choices")),
      );
    }
    return validators;
  }
  get_options() {
    const ret = { name: this.name, type: this.type };
    for (const name of this.get_option_names()) {
      if (this[name] !== undefined) {
        ret[name] = this[name];
      }
    }
    if (ret.attrs) {
      ret.attrs = clone(ret.attrs);
    } else {
      ret.attrs = {};
    }
    return ret;
  }
  json() {
    const res = this.get_options();
    // delete res.error_messages;
    if (typeof res.default === "function") {
      delete res.default;
    }
    if (typeof res.choices === "function") {
      delete res.choices;
    }
    if (!res.tag) {
      if (Array.isArray(res.choices) && res.choices.length > 0 && !res.autocomplete) {
        res.tag = "select";
      } else {
        res.tag = "input";
      }
    }
    if (res.tag === "input" && res.lazy === undefined) {
      res.lazy = true;
    }
    if (res.preload === undefined && (res.choices_url || res.choices_url_admin)) {
      res.preload = false;
    }
    return res;
  }
  widget_attrs(extra_attrs) {
    return { required: this.required, readonly: this.disabled, ...extra_attrs };
  }
  validate(value, ctx) {
    if (typeof value === "function") {
      return value;
    }
    for (const validator of this.validators) {
      try {
        value = validator(value, ctx);
      } catch (error) {
        if (error instanceof Validators.SkipValidateError) {
          return value;
        } else {
          throw error;
        }
      }
    }
    return value;
  }
  get_default(ctx) {
    if (typeof this.default !== "function") {
      return this.default;
    } else {
      return this.default(ctx);
    }
  }
  make_error(message, index) {
    return {
      type: "field_error",
      message,
      index,
      name: this.name,
      label: this.label,
    };
  }
  to_form_value(value) {
    // Fields like alioss* need this
    // console.log("base to_form_value");
    return value;
  }
  to_post_value(value) {
    return value;
  }
  get_antd_rule() {
    const rule = {
      whitespace: true,
    };
    rule.validator = async (_rule, value) => {
      try {
        return Promise.resolve(this.validate(value));
      } catch (error) {
        return Promise.reject(error);
      }
    };
    return rule;
  }
  choices_callback(choice) {
    if (PRIMITIVE_TYPES[typeof choice]) {
      return { value: choice, label: String(choice) };
    } else if (typeof choice == "object") {
      return { value: choice.value, label: choice.label, hint: choice.hint };
    } else {
      return { value: String(choice), label: String(choice) };
    }
  }
}

function get_max_choice_length(choices) {
  let n = 0;
  for (const c of choices) {
    const value = c.value;
    const n1 = value.length;
    if (n1 > n) {
      n = n1;
    }
  }
  return n;
}

class string extends basefield {
  static option_names = [
    "compact",
    "trim",
    "pattern",
    "length",
    "minlength",
    "maxlength",
    "input_type",
  ];
  constructor(options) {
    if (!options.choices && !options.length && !options.maxlength) {
      throw new Error(
        `field '${options.name}' must define maxlength or choices or length`,
      );
    }
    super({
      type: "string",
      db_type: "varchar",
      compact: true,
      trim: true,
      ...options,
    });
    if (this.default === undefined && !this.primary_key && !this.unique) {
      this.default = "";
    }
    if (Array.isArray(this.choices) && this.choices.length > 0) {
      const n = get_max_choice_length(this.choices);
      assert(
        n > 0,
        "invalid string choices(empty choices or zero length value):" + this.name,
      );
      const m = this.length || this.maxlength;
      if (!m || n > m) {
        this.maxlength = n;
      }
    }
  }
  get_validators(validators) {
    for (const e of ["pattern", "length", "minlength", "maxlength"]) {
      if (this[e]) {
        validators.unshift(Validators[e](this[e], this.get_error_message(e)));
      }
    }
    if (this.compact) {
      validators.unshift(Validators.delete_spaces);
    } else if (this.trim) {
      validators.unshift(Validators.trim);
    }
    validators.unshift(Validators.string);
    return super.get_validators(validators);
  }
  widget_attrs(extra_attrs) {
    const attrs = { minlength: this.minlength };
    return {
      ...basefield.prototype.widget_attrs.call(this),
      ...attrs,
      ...extra_attrs,
    };
  }
  to_form_value(value) {
    if (!value) {
      return "";
    }
    return typeof value == "string" ? value : String(value);
  }
  to_post_value(value) {
    return this.compact ? value?.replace(/\s/g, "") : value || "";
  }
}

class text extends basefield {
  static option_names = ["trim", "pattern"];
  constructor(options) {
    super({ type: "text", db_type: "text", ...options });
    if (this.default === undefined) {
      this.default = "";
    }
    if (this.attrs.auto_size === undefined) {
      this.attrs.auto_size = true;
    }
  }
}

class sfzh extends string {
  constructor(options) {
    super({ type: "sfzh", db_type: "varchar", length: 18, ...options });
  }
  get_validators(validators) {
    validators.unshift(Validators.sfzh);
    return super.get_validators(validators);
  }
}

class email extends string {
  constructor(options) {
    super({ type: "email", db_type: "varchar", maxlength: 255, ...options });
  }
  get_validators(validators) {
    validators.unshift(Validators.email);
    return super.get_validators(validators);
  }
}

class password extends string {
  constructor(options) {
    super({ type: "password", db_type: "varchar", maxlength: 255, ...options });
  }
}

class year_month extends string {
  constructor(options) {
    super({ type: "year_month", db_type: "varchar", length: 7, ...options });
  }
  get_validators(validators) {
    validators.unshift(Validators.year_month);
    return super.get_validators(validators);
  }
}

function add_min_or_max_validators(self, validators) {
  for (const name of ["min", "max"]) {
    if (self[name]) {
      validators.unshift(Validators[name](self[name], self.get_error_message(name)));
    }
  }
}

class integer extends basefield {
  static option_names = ["min", "max", "step", "serial"];
  constructor(options) {
    super({ type: "integer", db_type: "integer", ...options });
  }
  get_validators(validators) {
    add_min_or_max_validators(this, validators);
    validators.unshift(Validators.integer);
    return super.get_validators(validators);
  }
  json() {
    const json = super.json();
    if (json.primary_key && json.disabled === undefined) {
      json.disabled = true;
    }
    return json;
  }
  prepare_for_db(value, data) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}

class year extends integer {
  constructor(options) {
    super({
      type: "year",
      db_type: "integer",
      min: 1000,
      max: 9999,
      ...options,
    });
  }
}

class month extends integer {
  constructor(options) {
    super({ type: "month", db_type: "integer", min: 1, max: 12, ...options });
  }
}

class float extends basefield {
  static option_names = ["min", "max", "step", "precision"];
  constructor(options) {
    super({ type: "float", db_type: "float", ...options });
  }
  get_validators(validators) {
    add_min_or_max_validators(this, validators);
    validators.unshift(Validators.number);
    return super.get_validators(validators);
  }
  prepare_for_db(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}

const DEFAULT_BOOLEAN_CHOICES = [
  { label: "是", value: "true", text: "是" },
  { label: "否", value: "false", text: "否" },
];
class boolean extends basefield {
  static option_names = ["cn"];
  constructor(options) {
    super({ type: "boolean", ...options });
    if (this.choices === undefined) {
      this.choices = clone(DEFAULT_BOOLEAN_CHOICES);
    }
    return this;
  }
  get_validators(validators) {
    if (this.cn) {
      validators.unshift(Validators.boolean_cn);
    } else {
      validators.unshift(Validators.boolean);
    }
    return super.get_validators(validators);
  }
  prepare_for_db(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}

class datetime extends basefield {
  static option_names = ["auto_now_add", "auto_now", "precision", "timezone"];
  constructor(options) {
    super({
      type: "datetime",
      db_type: "timestamp",
      precision: 0,
      timezone: true,
      ...options,
    });
    if (this.auto_now_add) {
      this.default = get_localtime;
    }
    return this;
  }
  get_validators(validators) {
    validators.unshift(Validators.datetime);
    return super.get_validators(validators);
  }
  json() {
    const ret = super.json();
    if (ret.disabled === undefined && (ret.auto_now || ret.auto_now_add)) {
      ret.disabled = true;
    }
    return ret;
  }
  prepare_for_db(value) {
    if (this.auto_now) {
      return get_localtime();
    } else if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}

class date extends basefield {
  constructor(options) {
    super({ type: "date", ...options });
  }
  get_validators(validators) {
    validators.unshift(Validators.date);
    return super.get_validators(validators);
  }
  prepare_for_db(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}

class time extends basefield {
  static option_names = ["precision", "timezone"];
  constructor(options) {
    super({ type: "time", precision: 0, timezone: true, ...options });
  }
  get_validators(validators) {
    validators.unshift(Validators.time);
    return super.get_validators(validators);
  }
  prepare_for_db(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}

const VALID_FOREIGN_KEY_TYPES = {
  foreignkey: String,
  string: String,
  sfzh: String,
  integer: Validators.integer,
  float: Validators.float,
  datetime: Validators.datetime,
  date: Validators.date,
  time: Validators.time,
};

class foreignkey extends basefield {
  static option_names = [
    "reference",
    "reference_column",
    "reference_label_column",
    "reference_url",
    "reference_url_admin",
    "on_delete",
    "on_update",
    "table_name",
    "admin_url_name",
    "models_url_name",
    "keyword_query_name",
    "limit_query_name",
    "max_display_count", //前端autocomplete.choices最大展示数
    "max_choices_count", // 前端autocomplete.choices最大数
  ];
  constructor(options) {
    super({
      type: "foreignkey",
      db_type: FK_TYPE_NOT_DEFIEND,
      FK_TYPE_NOT_DEFIEND,
      on_delete: "CASCADE",
      on_update: "CASCADE",
      admin_url_name: "admin",
      models_url_name: "model",
      keyword_query_name: "keyword",
      limit_query_name: "limit",
      max_choices_count: 100,
      max_display_count: 50,
      convert: String,
      ...options,
    });
    const fk_model = this.reference;
    if (fk_model === "self") {
      return this;
    }
    this.setup_with_fk_model(fk_model);
  }
  setup_with_fk_model(fk_model) {
    assert(
      fk_model.__is_model_class__,
      `a foreignkey must define a reference model. not ${fk_model}(type: ${typeof fk_model})`,
    );
    const rc =
      this.reference_column ||
      fk_model.primary_key ||
      fk_model.DEFAULT_PRIMARY_KEY ||
      "id";
    const fk = fk_model.fields[rc];
    assert(
      fk,
      `invalid foreignkey name ${rc} for foreign model ${
        fk_model.table_name || "[TABLE NAME NOT DEFINED YET]"
      }`,
    );
    this.reference_column = rc;
    const rlc = this.reference_label_column || fk_model.referenced_label_column || rc;
    let _fk;
    let _fk_of_fk;
    const matches = rlc.match(/(\w+)__(\w+)/);
    if (matches) {
      _fk = matches[1];
      _fk_of_fk = matches[2];
    }
    const check_key = _fk || rlc;
    assert(
      fk_model.fields[check_key],
      `invalid foreignkey label name ${check_key} for foreign model ${
        fk_model.table_name || "[TABLE NAME NOT DEFINED YET]"
      }`,
    );
    this.reference_label_column = rlc;
    this.convert = assert(
      VALID_FOREIGN_KEY_TYPES[fk.type],
      `invalid foreignkey (name:${fk.name}, type:${fk.type})`,
    );
    assert(fk.primary_key || fk.unique, "foreignkey must be a primary key or unique key");
    if (this.db_type === FK_TYPE_NOT_DEFIEND) {
      this.db_type = fk.db_type || fk.type;
    }
  }
  get_validators(validators) {
    const foreignkey_validator = (v) => {
      if (this._postValue === null) {
        throw new Error(`无效的值，请在下拉列表中选择`);
      }
      return v;
    };
    validators.unshift(foreignkey_validator);
    // const foreignkey_autocomplete_validator = (v) => {
    //   console.log("foreignkey_autocomplete_validator", v);
    //   if (this.autocomplete && Array.isArray(this.choices)) {
    //     // 前端,需要进行双检查
    //     const matchedChoice = this.choices.find((e) => e.label === v);
    //     console.log("this.choices", this.choices, matchedChoice);
    //     if (matchedChoice) {
    //       return matchedChoice.value;
    //     }
    //     if (this.choices.some((e) => e.value === v)) {
    //       return v;
    //     }
    //     throw new Error("输入错误，请输入关键字然后在下拉列表中选取");
    //   } else {
    //     return v;
    //   }
    // };
    // validators.unshift(foreignkey_autocomplete_validator);
    return super.get_validators(validators);
  }
  load(value) {
    //TODO: 用Proxy改写以便和后端一致
    const fk_name = this.reference_column;
    const fk_model = this.reference;
    return fk_model.create_record({ [fk_name]: value });
  }
  json() {
    const ret = super.json();
    ret.reference = this.reference.table_name;
    ret.autocomplete = true;
    ret.choices_url_admin = `/${ret.admin_url_name}/${ret.models_url_name}/${ret.table_name}/fk/${ret.name}/${ret.reference_label_column}`;
    ret.reference_url_admin = `/${ret.admin_url_name}/${ret.models_url_name}/${ret.reference}`;
    if (ret.choices_url === undefined) {
      ret.choices_url = `/${ret.reference}/choices?value=${ret.reference_column}&label=${ret.reference_label_column}`;
    }
    if (ret.reference_url === undefined) {
      ret.reference_url = `/${ret.reference}/json`;
    }
    return ret;
  }
  prepare_for_db(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
  to_post_value(value, values) {
    return this._postValue ?? value;
  }
  to_form_value(value, values) {
    if (typeof value == "object") {
      return value[this.reference_label_column] ?? value[this.reference_column];
    }
    // 后端按raw():get()输出
    return values[`${this.name}__${this.reference_label_column}`] ?? value;
  }
}

class json extends basefield {
  constructor(options) {
    super({ type: "json", db_type: "jsonb", ...options });
  }
  json() {
    const json = super.json();
    json.tag = "textarea";
    return json;
  }
  prepare_for_db(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return Validators.encode(value);
    }
  }
}

function skip_validate_when_string(v) {
  if (typeof v === "string") {
    throw new Validators.SkipValidateError();
  } else {
    return v;
  }
}
function check_array_type(v) {
  if (!Array.isArray(v)) {
    throw new Error("value of array field must be a array");
  } else {
    return v;
  }
}
function non_empty_array_required(message) {
  message = message || "此项必填";
  function array_required_validator(v) {
    if (v.length === 0) {
      throw new Error(message);
    } else {
      return v;
    }
  }
  return array_required_validator;
}

class basearray extends json {
  constructor(options) {
    super(options);
    if (typeof this.default === "string") {
      this.default = string_choices_to_array(this.default);
    }
  }
  get_validators(validators) {
    if (this.required) {
      validators.unshift(non_empty_array_required(this.get_error_message("required")));
    }
    validators.unshift(check_array_type);
    validators.unshift(skip_validate_when_string);
    // validators.push(Validators.encode_as_array);
    return super.get_validators(validators);
  }
  get_empty_value_to_update() {
    return [];
  }
  to_form_value(value) {
    if (Array.isArray(value)) {
      // 拷贝, 避免弹出表格修改了值但没有提交
      return [...value];
    } else {
      return [];
    }
  }
}

class array extends basearray {
  static option_names = ["field"];
  constructor(options) {
    super({ type: "array", ...options });
    assert(
      typeof this.field === "object",
      `array field "${this.name}" must define field`,
    );
    if (!this.field.name) {
      // 为了解决validateFunction内array field覆盖paren值的问题
      this.field.name = this.name;
    }
    const fields = {
      // basefield,
      string,
      sfzh,
      email,
      password,
      text,
      integer,
      float,
      datetime,
      date,
      year_month,
      year,
      month,
      time,
      // json,
      // array: array,
      // table: table,
      foreignkey,
      boolean,
      alioss,
      alioss_image,
      // alioss_list: alioss_list,
      // alioss_image_list: alioss_image_list,
    };
    const array_field_cls = fields[this.field.type || "string"];
    if (!array_field_cls) {
      throw new Error("invalid array type: " + this.field.type);
    }
    this.field = array_field_cls.create_field(this.field);
  }
  get_options() {
    const options = super.get_options();
    const array_field_options = this.field.get_options();
    options.field = array_field_options;
    return options;
  }
  get_validators(validators) {
    const array_validator = (value) => {
      const res = [];
      const field = this.field;
      for (const [i, e] of value.entries()) {
        try {
          let val = field.validate(e);
          if (field.default && (val === undefined || val === "")) {
            if (typeof field.default !== "function") {
              val = field.default;
            } else {
              val = field.default();
            }
          }
          res[i] = val;
        } catch (error) {
          error.index = i;
          throw error;
        }
      }
      return res;
    };
    validators.unshift(array_validator);
    return super.get_validators(validators);
  }
  to_post_value(value) {
    if (Array.isArray(value)) {
      // 拷贝, 避免弹出表格修改了值但没有提交
      return [...value.map((e) => this.field.to_post_value(e))];
    } else if (value === undefined) {
      return [];
    } else {
      throw new Error(`${this.name}的值必须是数组(${typeof value}))`);
    }
  }
  to_form_value(value) {
    if (Array.isArray(value)) {
      return [...value.map((e) => this.field.to_form_value(e))];
    } else {
      return [];
    }
  }
}

function make_empty_array() {
  return [];
}

class table extends basearray {
  static option_names = ["model", "max_rows", "uploadable", "columns"];
  constructor(options) {
    super({ type: "table", max_rows: TABLE_MAX_ROWS, ...options });
    if (!this.model?.__is_model_class__) {
      this.model = Model.create_model(this.model);
      // throw new Error("please define model for a table field: " + this.name);
    }
    if (!this.default || this.default === "") {
      this.default = make_empty_array;
    }
    if (!this.model.table_name) {
      this.model.materialize_with_table_name({
        table_name: this.name,
        label: this.label,
      });
    }
  }
  get_validators(validators) {
    const validate_by_each_field = (rows) => {
      for (let [i, row] of rows.entries()) {
        assert(typeof row === "object", "elements of table field must be object");
        try {
          row = this.model.validate_create(row);
        } catch (err) {
          err.index = i;
          throw err;
        }
        rows[i] = row;
      }
      return rows;
    };
    validators.unshift(validate_by_each_field);
    return super.get_validators(validators);
  }
  json() {
    const ret = super.json();
    const model = {
      field_names: [],
      fields: {},
      table_name: this.model.table_name,
      label: this.model.label,
    };
    for (const name of this.model.field_names) {
      const field = this.model.fields[name];
      model.field_names.push(name);
      model.fields[name] = field.json();
    }
    ret.model = model;
    return ret;
  }
  load(rows) {
    if (!Array.isArray(rows)) {
      throw new Error("value of table field must be table, not " + typeof rows);
    }
    for (let i = 0; i < rows.length; i = i + 1) {
      rows[i] = this.model.load(rows[i]);
    }
    return rows;
  }
}

const ALIOSS_BUCKET = process.env.ALIOSS_BUCKET || "";
const ALIOSS_REGION = process.env.ALIOSS_REGION || "";
const ALIOSS_SIZE = process.env.ALIOSS_SIZE || "1MB";
const ALIOSS_LIFETIME = Number(process.env.ALIOSS_LIFETIME) || 30;
const map_to_antd_file_value = (url = "") => {
  const name = url.split("/").pop();
  return typeof url == "object"
    ? url
    : {
        name,
        status: "done",
        url,
        extname: name.split(".")[1], // uni
        ossUrl: url,
      };
};
class alioss extends string {
  static option_names = [
    "size",
    "size_arg",
    "policy",
    "payload",
    "lifetime",
    "key_secret",
    "key_id",
    "times",
    "width",
    "hash",
    "image",
    "prefix",
    "upload_url",
    "payload_url",
    "input_type",
    "limit",
    "media_type",
  ];
  constructor(options) {
    super({ type: "alioss", db_type: "varchar", maxlength: 255, ...options });
    this.setup(options);
  }
  setup(options) {
    const size = options.size || ALIOSS_SIZE;
    this.key_secret = options.key_secret;
    this.key_id = options.key_id;
    this.size_arg = size;
    this.size = parse_size(size);
    this.lifetime = options.lifetime || ALIOSS_LIFETIME;
    this.upload_url = `//${options.bucket || ALIOSS_BUCKET}.${
      options.region || ALIOSS_REGION
    }.aliyuncs.com/`;
  }
  get_options() {
    const ret = super.get_options();
    ret.size = ret.size_arg;
    delete ret.size_arg;
    return ret;
  }
  get_default() {
    return [];
  }
  async get_payload(options) {
    const { data } = await basefield.Http.post(this.payload_url, {
      ...options,
      size: options.size || this.size,
      lifetime: options.lifetime || this.lifetime,
    });
    return data;
  }
  get_validators(validators) {
    // TODO: 暂时禁用验证
    return [];
  }
  json() {
    const ret = super.json();
    if (ret.input_type === undefined) {
      ret.input_type = "file";
    }
    delete ret.key_secret;
    delete ret.key_id;
    return ret;
  }
  to_form_value(url) {
    if (this.attrs.wx_avatar) {
      return url || "";
    }
    if (typeof url == "string") {
      return url ? [map_to_antd_file_value(url)] : [];
    } else if (Array.isArray(url)) {
      return [...url];
    } else {
      return [];
    }
  }
  to_post_value(file_list) {
    if (this.attrs?.wx_avatar) {
      return file_list;
    } else if (!Array.isArray(file_list) || !file_list[0]) {
      return "";
    } else {
      return file_list[0].ossUrl || "";
    }
  }
}

class alioss_image extends alioss {
  constructor(options) {
    super({
      type: "alioss_image",
      db_type: "varchar",
      media_type: "image",
      image: true,
      ...options,
    });
  }
}

class alioss_list extends basearray {
  constructor(options) {
    super({
      type: "alioss_list",
      db_type: "jsonb",
      ...options,
    });
    alioss.prototype.setup.call(this, options);
  }
  async get_payload(options) {
    return await alioss.prototype.get_payload.call(this, options);
  }
  get_options() {
    return alioss.prototype.get_options.call(this);
  }
  json() {
    return { ...alioss.prototype.json.call(this), ...super.json() };
  }
  to_form_value(urls) {
    if (Array.isArray(urls)) {
      return urls.map(map_to_antd_file_value);
    } else {
      return [];
    }
  }
  to_post_value(file_list) {
    if (!Array.isArray(file_list) || !file_list[0]) {
      return [];
    } else {
      return file_list.map((e) => e.ossUrl);
    }
  }
}

class alioss_image_list extends alioss_list {
  constructor(options) {
    super({
      type: "alioss_image_list",
      // media_type: "image",
      // image: true,
      ...options,
    });
  }
}

export {
  basefield,
  string,
  sfzh,
  email,
  password,
  text,
  integer,
  float,
  datetime,
  date,
  year_month,
  year,
  month,
  time,
  json,
  array,
  table,
  foreignkey,
  boolean,
  alioss,
  alioss_image,
  alioss_list,
  alioss_image_list,
};
