#!/usr/bin/env node
require("shelljs/global");
const prettier = require("prettier");
const fs = require("fs");
var path = require("path");

const ret = require("yargs/yargs")(process.argv.slice(2)).parse();
console.log({ ret });
const {
  _: [model],
  type,
  label,
  url,
  fields,
  ...args
} = ret;
// { _: [ 'ThreadList' ], t: 'list', '$0': 'bin\\page.js' }

console.log({ args, model, type });

const modelName = model.charAt(0).toUpperCase() + model.slice(1);
const tableName = modelName.toLowerCase();
const pageName =
  type == "list"
    ? `${modelName}List`
    : type == "detail"
    ? `${modelName}Detail`
    : `${modelName}`;

console.log({ modelName, tableName, pageName });
var views = require("../src/views.json");

const renderTemplate = ({ src, dest, context, srcString }) => {
  srcString = srcString || fs.readFileSync(src, { flag: "r" }).toString();
  for (const [key, value] of Object.entries(context)) {
    const reg = "\\{\\{\\s*" + key + "\\s*\\}\\}";
    srcString = srcString.replaceAll(new RegExp(reg, "g"), value);
  }
  srcString = srcString
    .split("\n")
    .map((line) => line.replaceAll(/^\s*\/\/.+$/g, ""))
    .filter((line) => line)
    .join("\n");
  if (dest) {
    console.log({ dest, pdest: `src/views/${pageName}` });
    fs.mkdirSync(`src/views/${pageName}`, { recursive: true });
    fs.writeFileSync(dest, srcString);
  }
  return srcString;
};

const context = {
  modelName,
  tableName
};
const formItemSnippet = `
      <uni-forms-item label="{{label}}" name="{{name}}">
        <uni-easyinput v-model="{{modelName}}Data.{{name}}" />
      </uni-forms-item>
`;
const formRuleSnippet = `
{{name}}: {
  rules: [
    {
      required: true,
      errorMessage: "{{label}}不能为空",
    },
    {
      validateFunction: function (rule, value, data, callback) {
        if (value.length > 255) {
          callback("字数不能超过255");
        }
        return true;
      },
    },
  ],
},
`;
if (type == "list") {
  context.url = url || `/${modelName}/list`;
} else if (type == "form") {
  const formItemToken = [];
  const dataToken = [];
  const rulesToken = [];
  for (const fieldStr of fields.split(";")) {
    const [name, label] = fieldStr.trim().split(",");
    dataToken.push(`${name}:""`);
    rulesToken.push(
      renderTemplate({
        srcString: formRuleSnippet,
        context: { ...context, name: name.trim(), label: label.trim() }
      })
    );
    formItemToken.push(
      renderTemplate({
        srcString: formItemSnippet,
        context: { ...context, name: name.trim(), label: label.trim() }
      })
    );
  }
  context.formItemToken = formItemToken.join("\n");
  context.dataToken = `{${dataToken.join(",")}}`;
  context.rulesToken = `{${rulesToken.join("\n")}}`;
}
renderTemplate({
  src: `bin/views/${type || "detail"}.vue`,
  dest: `src/views/${pageName}.vue`,
  context
});

const pagePath = `views/${pageName}`;
views.views = [
  ...views.views.filter((p) => p.path !== pagePath),
  {
    path: pagePath,
    style: { navigationBarTitleText: label || "..." }
  }
];
const pageJson = JSON.stringify(views);
const formatedJson = prettier.format(pageJson, { parser: "json" });

fs.writeFileSync("src/views.json", formatedJson);
