import { $, chalk, argv } from "zx";
import fs from "fs";
import ejs from "ejs";
import makeControllers from "./make-controllers.mjs";

const green = (s) => console.log(chalk.green(s));
const red = (s) => console.log(chalk.red(s));

const capitalize = (s) => s.charAt(0).toUpperCase() + s.slice(1);
const snakeToCamel = (s) => {
  return s.replace(/(_[a-zA-Z])/g, (c) => {
    return c[1].toUpperCase();
  });
};

const toPascalName = (s) => {
  return capitalize(snakeToCamel(s));
};

async function preprocess(opts) {
  if (opts.model) {
    if (!Array.isArray(opts.model)) {
      opts.model = opts.model.split(",");
    }
  } else {
    opts.model = opts._;
  }
}

async function make(opts) {
  const app = opts.name;
  const appName = toPascalName(app);
  const force = opts.force || opts.f;
  const ctx = {
    appName,
    modelNames: opts.model,
    modelPascalNames: opts.model.map(toPascalName),
    labels: opts.label,
    tableNames: opts.table_name,
    appLogo: opts.logo || `${appName}`,
  };
  const renderFile = ({ src, dest, kwargs = {} }) => {
    if (fs.existsSync(dest) && !force) {
      red(`MAKE: ${dest} already exists, skip`);
      return;
    }
    ejs.renderFile(src, { ...ctx, ...kwargs }, {}, function (err, str) {
      if (err) {
        throw err;
      }
      fs.writeFileSync(dest, str);
      green(`MAKE: ${dest}`);
    });
  };
  renderFile({
    src: "template/Model.vue.ejs",
    dest: `src/views/${appName}.vue`,
  });
  renderFile({
    src: "template/ModelPanel.vue.ejs",
    dest: `src/views/${appName}/${appName}Panel.vue`,
  });
  for (const [i, modelName] of opts.model.map(toPascalName).entries()) {
    for (const actionName of ["Create", "Update", "List", "Detail"]) {
      renderFile({
        src: `template/Model${actionName}.vue.ejs`,
        dest: `src/views/${modelName}${actionName}.vue`,
        kwargs: { modelName, tableName: opts.table_name[i] },
      });
    }
  }
}
async function clear(opts) {
  const app = opts.name;
  const appName = toPascalName(app);
  await $`rm -rf src/views/${appName}`;
  await $`rm src/views/${appName}.vue`;
  red(`DELETE src/views/${appName}`);
  red(`DELETE src/views/${appName}.vue`);
  if (opts.controllers || opts.c) {
    await makeControllers(opts);
  }
}
async function main(opts = argv) {
  // console.log("make-app:", opts);
  await preprocess(opts);
  if (opts.clear || opts.rollback) {
    await clear(opts);
  } else {
    await make(opts);
  }
}
main().then((res) => {
  green("----------");
});
export default main;
