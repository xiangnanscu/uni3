import * as Validator from "./validator";
import { Http } from "@/globals/Http";

const TABLE_MAX_ROWS = 1;
const CHOICES_ERROR_DISPLAY_COUNT = 30;
const ERROR_MESSAGES = { required: "此项必填", choices: "无效选项" };
const NULL = {};
const NOT_DEFIEND = {};
const PRIMITIVE_TYPES = {
  string: true,
  number: true,
  boolean: true,
  bigint: true
};

// const repr = (e) => JSON.stringify(e);
function assert(bool, errMsg) {
  if (!bool) {
    throw new Error(errMsg);
  } else {
    return bool;
  }
}
function getLocalTime(d = new Date()) {
  return `${d.getFullYear()}-${
    d.getMonth() + 1
  }-${d.getDate()} ${d.getHours()}:${d.getMinutes()}:${d.getSeconds()}`;
}
function cleanChoice(c) {
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
function getChoices(rawChoices) {
  const choices = [];
  for (let c of rawChoices) {
    if (typeof c === "string" || typeof c === "number") {
      c = { value: c, label: c, text: c };
    } else if (typeof c === "object") {
      const [value, label, hint] = cleanChoice(c);
      c = { value, label, hint, text: label };
    } else {
      throw new Error("invalid choice type:" + typeof c);
    }
    choices.push(c);
  }
  return choices;
}
function serializeChoice(choice) {
  return String(choice.value);
}
function getChoicesErrorMessage(choices) {
  const validChoices = choices.map(serializeChoice).join("，");
  return `限下列选项：${validChoices}`;
}
function getChoicesValidator(choices, message) {
  if (choices.length <= CHOICES_ERROR_DISPLAY_COUNT) {
    message = `${message}，${getChoicesErrorMessage(choices)}`;
  }
  const isChoice = [];
  for (const c of choices) {
    isChoice[c.value] = true;
  }
  function choicesValidator(value) {
    if (!isChoice[value]) {
      throw new Error(message);
    } else {
      return value;
    }
  }
  return choicesValidator;
}
const databaseOptionNames = ["primaryKey", "null", "unique", "index", "dbType"];
const baseOptionNames = [
  ...databaseOptionNames,
  "required",
  "label",
  "style",
  "choices",
  "choicesUrl",
  "choicesUrlMethod",
  // "choicesCallback", // antdv
  "autocomplete",
  "strict",
  "disabled",
  "errorMessages",
  "default",
  "hint",
  "lazy",
  "tag",
  "image",
  "url",
  "columns",
  "verifyUrl",
  "postNames",
  "codeLifetime",
  "tooltipVisible"
];

class BaseField {
  static getLocalTime = getLocalTime;
  static NOT_DEFIEND = NOT_DEFIEND;
  __is_field_class__ = true;
  required = false;
  get optionNames() {
    // define as getter so the subclass optionNames can be accessed in super call
    return baseOptionNames;
  }
  static new(options) {
    const self = new this(options);
    self.validators = self.getValidators([]);
    return self;
  }
  constructor(options) {
    Object.assign(this, this.getOptions(options));
    if (this.dbType === undefined) {
      this.dbType = this.type;
    }
    if (this.label === undefined) {
      this.label = this.name;
    }
    if (this.null === undefined) {
      if (!this.required && this.type !== "string") {
        this.null = true;
      } else {
        this.null = false;
      }
    }
    if (typeof this.choicesUrl == "string") {
      this.choices = this.choices ? this.choices.map(this.choicesCallback) : [];
    }
    if (this.choices) {
      if (this.strict === undefined) {
        this.strict = true;
      }
      if (Array.isArray(this.choices)) {
        this.choices = getChoices(this.choices);
      } else {
        throw new Error("invalid choices type: " + typeof this.choices);
      }
    }
    this.errorMessages = { ...ERROR_MESSAGES, ...this.errorMessages };
    return this;
  }

  getOptions(options) {
    if (!options) {
      options = this;
    }
    const ret = {
      name: options.name,
      type: options.type
    };
    for (const name of this.optionNames) {
      if (options[name] !== undefined) {
        ret[name] = options[name];
      }
    }
    return ret;
  }
  getValidators(validators) {
    if (this.required) {
      validators.unshift(Validator.required(this.errorMessages.required));
    } else {
      validators.unshift(Validator.notRequired);
    }
    if (this.strict) {
      if (this.choicesUrl) {
        // dynamic choices, need to access this at runtime
        validators.push((val) => {
          for (const { value } of this.choices) {
            if (val === value) {
              return value;
            }
          }
          throw new Error("无效选项, 请通过点击下拉框的形式输入");
        });
      } else if (Array.isArray(this.choices)) {
        // static choices
        validators.push(
          getChoicesValidator(this.choices, this.errorMessages.choices)
        );
      }
    }
    return validators;
  }
  toFormValue(value) {
    // Fields like alioss* need this
    // console.log("base toFormValue");
    return value;
  }
  toPostValue(value) {
    return value;
  }
  getAntdRule() {
    const rule = {
      whitespace: true
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
  json() {
    const json = this.getOptions();
    delete json.errorMessages;
    if (typeof json.default === "function") {
      delete json.default;
    }
    if (typeof json.choices === "function") {
      delete json.choices;
    }
    if (!json.tag) {
      if (json.choices && json.choices.length > 0 && !json.autocomplete) {
        json.tag = "select";
      } else {
        json.tag = "input";
      }
    }
    if (json.tag === "input" && json.lazy === undefined) {
      json.lazy = true;
    }
    return json;
  }
  widgetAttrs(extraAttrs) {
    return { required: this.required, readonly: this.disabled, ...extraAttrs };
  }
  validate(value, ctx) {
    if (typeof value === "function") {
      return value;
    }
    for (const validator of this.validators) {
      try {
        value = validator(value, ctx);
        if (value === undefined) {
          return;
        }
      } catch (error) {
        if (error instanceof Validator.SkipValidateError) {
          return value;
        } else {
          throw error;
        }
      }
    }
    return value;
  }
  getDefault(ctx) {
    if (typeof this.default !== "function") {
      return this.default;
    } else {
      return this.default(ctx);
    }
  }
  choicesCallback(choice) {
    if (PRIMITIVE_TYPES[typeof choice]) {
      return { value: choice, label: String(choice) };
    } else if (typeof choice == "object") {
      return { value: choice.value, label: choice.label, hint: choice.hint };
    } else {
      return { value: String(choice), label: String(choice) };
    }
  }
}
function getMaxChoiceLength(choices) {
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
const stringOptionNames = [
  ...baseOptionNames,
  "compact",
  "trim",
  "pattern",
  "length",
  "minlength",
  "maxlength"
];
const stringValidatorNames = ["pattern", "length", "minlength", "maxlength"];
class StringField extends BaseField {
  type = "string";
  dbType = "varchar";
  compact = true;
  trim = true;
  get optionNames() {
    return stringOptionNames;
  }
  constructor(options) {
    if (!options.choices && !options.length && !options.maxlength) {
      throw new Error(
        `field ${options.name} must define maxlength or choices or length`
      );
    }
    super(options);
    if (this.compact === undefined) {
      this.compact = true;
    }
    if (this.default === undefined && !this.primaryKey && !this.unique) {
      this.default = "";
    }
    if (Array.isArray(this.choices) && this.choices.length > 0) {
      const n = getMaxChoiceLength(this.choices);
      assert(
        n > 0,
        "invalid string choices(empty choices or zero length value):" +
          this.name
      );
      const m = this.length || this.maxlength;
      if (!m || n > m) {
        this.maxlength = n;
      }
    }
    return this;
  }
  getValidators(validators) {
    if (this.compact) {
      validators.unshift(Validator.deleteSpaces);
    } else if (this.trim) {
      validators.unshift(Validator.trim);
    }
    for (const e of stringValidatorNames) {
      if (this[e]) {
        validators.unshift(Validator[e](this[e], this.errorMessages[e]));
      }
    }
    validators.unshift(Validator.string);
    return super.getValidators(validators);
  }
  widgetAttrs(extraAttrs) {
    const attrs = { minlength: this.minlength };
    return { ...super.widgetAttrs(), ...attrs, ...extraAttrs };
  }
  toFormValue(value) {
    if (!value) {
      return "";
    }
    return typeof value == "string" ? value : String(value);
  }
  toPostValue(value) {
    return this.compact ? value.replace(/\s/g, "") : value;
  }
}

class SfzhField extends StringField {
  type = "sfzh";
  dbType = "varchar";
  constructor(options) {
    super({ ...options, length: 18 });
    return this;
  }
  getValidators(validators) {
    validators.unshift(Validator.sfzh);
    return super.getValidators(validators);
  }
}

class EmailField extends StringField {
  type = "email";
  dbType = "varchar";
  constructor(options) {
    super({ maxlength: 255, ...options });
    return this;
  }
}

class PasswordField extends StringField {
  type = "password";
  dbType = "varchar";
  constructor(options) {
    super({ maxlength: 255, ...options });
    return this;
  }
}

class YearMonthField extends StringField {
  type = "yearMonth";
  dbType = "varchar";
  constructor(options) {
    super({ length: 7, ...options });
    return this;
  }
  getValidators(validators) {
    validators.unshift(Validator.yearMonth);
    return super.getValidators(validators);
  }
}

class YearField extends StringField {
  type = "year";
  dbType = "varchar";
  constructor(options) {
    super({ length: 4, ...options });
    return this;
  }
  getValidators(validators) {
    validators.unshift(Validator.year);
    return super.getValidators(validators);
  }
}

const integerOptionNames = [...baseOptionNames, "min", "max", "step", "serial"];
const intergerValidatorNames = ["min", "max"];
class IntegerField extends BaseField {
  type = "integer";
  dbType = "integer";
  get optionNames() {
    return integerOptionNames;
  }
  addMinOrMaxValidators(validators) {
    for (const e of intergerValidatorNames) {
      if (this[e]) {
        validators.unshift(Validator[e](this[e], this.errorMessages[e]));
      }
    }
  }
  getValidators(validators) {
    this.addMinOrMaxValidators(validators);
    validators.unshift(Validator.integer);
    return super.getValidators(validators);
  }
  json() {
    const json = super.json();
    if (json.primaryKey && json.disabled === undefined) {
      json.disabled = true;
    }
    return json;
  }
  prepareForDb(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}
class TextField extends BaseField {
  type = "text";
  dbType = "text";
}

const floatValidatorNames = ["min", "max"];
const floatOptionNames = [
  ...baseOptionNames,
  "min",
  "max",
  "step",
  "precision"
];
class FloatField extends BaseField {
  type = "float";
  dbType = "float";
  get optionNames() {
    return floatOptionNames;
  }
  addMinOrMaxValidators(validators) {
    for (const e of floatValidatorNames) {
      if (this[e]) {
        validators.unshift(Validator[e](this[e], this.errorMessages[e]));
      }
    }
  }

  getValidators(validators) {
    this.addMinOrMaxValidators(validators);
    validators.unshift(Validator.number);
    return super.getValidators(validators);
  }
  prepareForDb(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}

const DEFAULT_BOOLEAN_CHOICES = [
  { label: "是", value: true, text: "是" },
  { label: "否", value: false, text: "否" }
];
const booleanOptionNames = [...baseOptionNames, "cn"];
class BooleanField extends BaseField {
  type = "boolean";
  dbType = "boolean";
  get optionNames() {
    return booleanOptionNames;
  }
  constructor(options) {
    super(options);
    if (this.choices === undefined) {
      this.choices = DEFAULT_BOOLEAN_CHOICES;
    }
    return this;
  }

  getValidators(validators) {
    if (this.cn) {
      validators.unshift(Validator.booleanCn);
    } else {
      validators.unshift(Validator.boolean);
    }
    return super.getValidators(validators);
  }
  prepareForDb(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}

const jsonOptionNames = [...baseOptionNames];
class JsonField extends BaseField {
  type = "json";
  dbType = "jsonb";
  get optionNames() {
    return jsonOptionNames;
  }
  json() {
    const json = super.json();
    json.tag = "textarea";
    return json;
  }
  prepareForDb(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return Validator.encode(value);
    }
  }
}
function skipValidateWhenString(v) {
  if (typeof v === "string") {
    throw new Validator.SkipValidateError();
  } else {
    return v;
  }
}
function checkArrayType(v) {
  if (!(v instanceof Array)) {
    throw new Error("value of array field must be a array");
  } else {
    return v;
  }
}
function nonEmptyArrayRequired(message) {
  message = message || "此项必填";
  function arrayValidator(v) {
    if (v.length === 0) {
      throw new Error(message);
    } else {
      return v;
    }
  }
  return arrayValidator;
}
const arrayOptionNames = [...baseOptionNames, "arrayType"];
class ArrayField extends JsonField {
  type = "array";
  dbType = "jsonb";
  get optionNames() {
    return arrayOptionNames;
  }
  getValidators(validators) {
    if (this.required) {
      validators.unshift(nonEmptyArrayRequired(this.errorMessages.required));
    }
    validators.unshift(checkArrayType);
    validators.unshift(skipValidateWhenString);
    return super.getValidators(validators);
  }
  getEmptyValueToUpdate() {
    return [];
  }
  toFormValue(value) {
    if (Array.isArray(value)) {
      // 拷贝, 避免弹出表格修改了值但没有提交
      return [...value];
    } else {
      return [];
    }
  }
}
function makeEmptyArray() {
  return [];
}

const tableOptionNames = [...baseOptionNames, "model", "maxRows", "uploadable"];
class TableField extends ArrayField {
  type = "table";
  maxRows = TABLE_MAX_ROWS;
  get optionNames() {
    return tableOptionNames;
  }
  constructor(options) {
    super(options);
    if (!this.model?.__isModelClass__) {
      throw new Error("please define model for a table field: " + this.name);
    }
    if (!this.default || this.default === "") {
      this.default = makeEmptyArray;
    }
    if (!this.model.tableName) {
      this.model.materializeWithTableName({
        tableName: this.name,
        label: this.label
      });
    }
    return this;
  }
  getValidators(validators) {
    function validateByEachField(rows) {
      for (let [i, row] of rows.entries()) {
        assert(
          typeof row === "object",
          "elements of table field must be object"
        );
        try {
          row = this.model.validateCreate(row);
        } catch (err) {
          err.index = i;
          throw err;
        }
        rows[i] = row;
      }
      return rows;
    }
    validators.unshift(validateByEachField);
    return super.getValidators(validators);
  }
  json() {
    const ret = super.json();
    const model = { fieldNames: [], fields: {} };
    for (const name of this.model.fieldNames) {
      const field = this.model.fields[name];
      model.fieldNames.push(name);
      model.fields[name] = field.json();
    }
    ret.model = model;
    return ret;
  }
  load(rows) {
    if (!(rows instanceof Array)) {
      throw new Error("value of table field must be table, not " + typeof rows);
    }
    for (let i = 0; i < rows.length; i = i + 1) {
      rows[i] = this.model.load(rows[i]);
    }
    return rows;
  }
}

const datetimeOptionNames = [
  ...baseOptionNames,
  "autoNowAdd",
  "autoNow",
  "precision",
  "timezone",
  "valueFormat", // antdv
  "timeFormat" // antdv
];
class DatetimeField extends BaseField {
  type = "datetime";
  dbType = "timestamp";
  precision = 0;
  timezone = true;
  get optionNames() {
    return datetimeOptionNames;
  }
  constructor(options) {
    super(options);
    if (this.autoNowAdd) {
      this.default = getLocalTime;
    }
    return this;
  }

  getValidators(validators) {
    validators.unshift(Validator.datetime);
    return super.getValidators(validators);
  }
  json() {
    const ret = super.json();
    if (ret.disabled === undefined && (ret.autoNow || ret.autoNowAdd)) {
      ret.disabled = true;
    }
    return ret;
  }
  prepareForDb(value) {
    if (this.autoNow) {
      return getLocalTime();
    } else if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}

const dateOptionNames = [...baseOptionNames, "valueFormat"];
class DateField extends BaseField {
  type = "date";
  dbType = "date";
  get optionNames() {
    return dateOptionNames;
  }
  getValidators(validators) {
    validators.unshift(Validator.date);
    return super.getValidators(validators);
  }
  prepareForDb(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
}
const timeOptionNames = [...baseOptionNames, "precision", "timezone"];
class TimeField extends BaseField {
  type = "time";
  dbType = "time";
  precision = 0;
  timezone = true;
  get optionNames() {
    return timeOptionNames;
  }
  getValidators(validators) {
    validators.unshift(Validator.time);
    return super.getValidators(validators);
  }
  prepareForDb(value) {
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
  integer: Validator.integer,
  float: Number,
  datetime: Validator.datetime,
  date: Validator.date,
  time: Validator.time
};
const foreignkeyOptionNames = [
  ...baseOptionNames,
  "reference",
  "referenceColumn",
  "referenceLabelColumn",
  "referenceUrl",
  "realtime",
  "adminUrlName",
  "modelUrlName",
  "keywordQueryName",
  "limitQueryName",
  "autocomplete",
  "choicesUrl",
  "tableName"
];
class ForeignkeyField extends BaseField {
  type = "foreignkey";
  adminUrlName = "admin";
  modelsUrlName = "model";
  convert = String;
  get optionNames() {
    return foreignkeyOptionNames;
  }
  constructor(options) {
    super({ dbType: NOT_DEFIEND, ...options });
    const fkModel = this.reference;
    if (fkModel === "self") {
      return this;
    }
    assert(
      fkModel.__isModelClass__,
      `a foreignkey must define reference model. not ${fkModel}(type: ${typeof fkModel})`
    );
    const rc = this.referenceColumn || fkModel.primaryKey || "id";
    const fk = fkModel.fields[rc];
    assert(
      fk,
      `invalid foreignkey name ${rc} for foreign model ${
        fkModel.tableName || "[TABLE NAME NOT DEFINED YET]"
      }`
    );
    this.referenceColumn = rc;
    const rlc = this.referenceLabelColumn || this.referenceColumn;
    assert(
      fkModel.fields[rlc],
      `invalid foreignkey label name ${rlc} for foreign model ${
        fkModel.tableName || "[TABLE NAME NOT DEFINED YET]"
      }`
    );
    this.referenceLabelColumn = rlc;
    this.convert = assert(
      VALID_FOREIGN_KEY_TYPES[fk.type],
      `invalid foreignkey (name:${fk.name}, type:${fk.type})`
    );
    assert(
      fk.primaryKey || fk.unique,
      "foreignkey must be a primary key or unique key"
    );
    if (this.dbType === NOT_DEFIEND) {
      this.dbType = fk.dbType || fk.type;
    }
    return this;
  }

  getValidators(validators) {
    const fkName = this.referenceColumn;
    const foreignkeyValidator = (v) => {
      if (typeof v === "object") {
        v = v[fkName];
      }
      try {
        v = this.convert(v);
      } catch (error) {
        throw new Error("error when converting foreign key:" + error.message);
      }
      return v;
    };
    validators.unshift(foreignkeyValidator);
    return super.getValidators(validators);
  }
  toFormValue(value) {
    if (typeof value == "object") {
      return value[this.referenceColumn];
    } else {
      return value;
    }
  }
  load(value) {
    //** todo 用Proxy改写
    const fkName = this.referenceColumn;
    const fkModel = this.reference;
    // function __index(t, key) {
    //   if (fkModel[key]) {
    //     return fkModel[key];
    //   } else if (fkModel.fields[key]) {
    //     let pk = rawget(t, fkName);
    //     if (!pk) {
    //       return undefined;
    //     }
    //     let res = fkModel.get({ [fkName]: pk });
    //     if (!res) {
    //       return undefined;
    //     }
    //     for (let [k, v] of Object.entries(res)) {
    //       rawset(t, k, v);
    //     }
    //     fkModel(t);
    //     return t[key];
    //   } else {
    //     return undefined;
    //   }
    // }
    // return setmetatable({ [fkName]: value }, { __index: __index });
    return fkModel.newRecord({ [fkName]: value });
  }
  prepareForDb(value) {
    if (value === "" || value === undefined) {
      return NULL;
    } else {
      return value;
    }
  }
  json() {
    const ret = super.json();
    ret.reference = this.reference.tableName;
    ret.autocomplete = true;
    if (ret.realtime === undefined) {
      ret.realtime = true;
    }
    if (ret.keywordQueryName === undefined) {
      ret.keywordQueryName = "keyword";
    }
    if (ret.limitQueryName === undefined) {
      ret.limitQueryName = "limit";
    }
    if (ret.choicesUrl === undefined) {
      ret.choicesUrl = `/${ret.adminUrlName}/${ret.modelsUrlName}/${ret.tableName}/fk/${ret.name}/${ret.referenceLabelColumn}`;
    }
    return ret;
  }
}

const sizeTable = {
  k: 1024,
  m: 1024 * 1024,
  g: 1024 * 1024 * 1024,
  kb: 1024,
  mb: 1024 * 1024,
  gb: 1024 * 1024 * 1024
};
function byteSizeParser(t) {
  if (typeof t === "string") {
    const unit = t.replaceAll(/^(\d+)([^\d]+)$/g, "$2").toLowerCase();
    const ts = t.replaceAll(/^(\d+)([^\d]+)$/g, "$1").toLowerCase();
    const bytes = sizeTable[unit];
    assert(bytes, "invalid size unit: " + unit);
    const num = Number(ts);
    assert(num, "can't convert `" + (ts + "` to a number"));
    return num * bytes;
  } else if (typeof t === "number") {
    return t;
  } else {
    throw new Error("invalid type:" + typeof t);
  }
}

const ALIOSS_BUCKET = process.env.ALIOSS_BUCKET || "";
const ALIOSS_REGION = process.env.ALIOSS_REGION || "";
const ALIOSS_SIZE = process.env.ALIOSS_SIZE || "1MB";
const ALIOSS_LIFETIME = Number(process.env.ALIOSS_LIFETIME) || 30;

const aliossOptionNames = [
  ...baseOptionNames,
  "size",
  "policy",
  "sizeArg",
  "times",
  "payload",
  "payloadUrl",
  "uploadUrl",
  "mediaType",
  "inputType",
  "image",
  "maxlength",
  "width",
  "prefix",
  "hash",
  "listType", // antdv
  "maxCount", // antdv
  "multiple", // antdv
  "accept", // antdv
  "buttonText" // antdv
];
const mapToAntdFileValue = (url = "") => {
  return typeof url == "object"
    ? url
    : {
        name: url.split("/").pop(),
        status: "done",
        url: url,
        ossUrl: url
      };
};
class AliossField extends StringField {
  type = "alioss";
  dbType = "varchar";
  constructor(options) {
    super({ maxlength: 255, ...options });
    const size = options.size || ALIOSS_SIZE;
    this.sizeArg = size;
    this.size = byteSizeParser(size);
    this.lifetime = options.lifetime || ALIOSS_LIFETIME;
    this.uploadUrl = process.env.ALIOSS_URL;
    return this;
  }
  get optionNames() {
    return aliossOptionNames;
  }
  async getPayload(options) {
    const { data } = await Http.post(this.payloadUrl, {
      ...options,
      size: options.size || this.size,
      lifetime: options.lifetime || this.lifetime
    });
    return data;
  }
  getValidators(validators) {
    // validators.unshift(Validator.url);
    // return super.getValidators(validators);
    return [];
  }
  getOptions(options) {
    const json = super.getOptions(options);
    if (json.sizeArg) {
      json.size = json.sizeArg;
      delete json.sizeArg;
    }
    return json;
  }
  toFormValue(url) {
    // console.log("call AliossField.toFormValue", JSON.stringify(url));
    if (typeof url == "string") {
      return url ? [mapToAntdFileValue(url)] : [];
    } else if (Array.isArray(url)) {
      return [...url];
    } else {
      return [];
    }
  }
  toPostValue(fileList) {
    if (!Array.isArray(fileList) || !fileList[0]) {
      return "";
    } else {
      return fileList[0].ossUrl || "";
    }
  }
  json() {
    const ret = super.json();
    if (ret.inputType === undefined) {
      ret.inputType = "file";
    }
    return ret;
  }
}

class AliossImageField extends AliossField {
  type = "aliossImage";
  dbType = "varchar";
}
class AliossListField extends AliossField {
  type = "aliossList";
  dbType = "jsonb";
  getValidators(validators) {
    return ArrayField.prototype.getValidators.call(this, validators);
  }
  getEmptyValueToUpdate() {
    return [];
  }
  getOptions(options) {
    return {
      ...ArrayField.prototype.getOptions.call(this, options),
      ...AliossField.prototype.getOptions.call(this, options),
      type: "aliossList",
      dbType: "jsonb"
    };
  }
  json() {
    return {
      ...ArrayField.prototype.json.call(this),
      ...AliossField.prototype.json.call(this)
    };
  }
  toFormValue(urls) {
    // console.log("call toFormValue2", JSON.stringify(urls));
    if (Array.isArray(urls)) {
      return urls.map(mapToAntdFileValue);
    } else {
      return [];
    }
  }
  toPostValue(fileList) {
    if (!Array.isArray(fileList) || !fileList[0]) {
      return [];
    } else {
      return fileList.map((e) => e.ossUrl);
    }
  }
}

class AliossImageListField extends AliossListField {
  type = "aliossImageList";
  dbType = "jsonb";
  constructor(options) {
    super(options);
    this.image = true;
  }
}
export {
  BaseField,
  StringField,
  EmailField,
  PasswordField,
  YearMonthField,
  YearField,
  TextField,
  IntegerField,
  FloatField,
  DatetimeField,
  DateField,
  TimeField,
  JsonField,
  ArrayField,
  TableField,
  ForeignkeyField,
  BooleanField,
  AliossField,
  AliossImageField,
  AliossListField,
  AliossImageListField,
  SfzhField
};
