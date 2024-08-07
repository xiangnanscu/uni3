import { $, chalk, argv } from "zx";
import fs from "fs";
import ejs from "ejs";

// yarn app -f display --table_name=display

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
  if (!opts.name) {
    opts.name = "xxx";
  }
  if (opts.model) {
    if (!Array.isArray(opts.model)) {
      opts.model = opts.model.split(",");
    }
  } else {
    opts.model = opts._;
  }
  if (!opts.table_name) {
    opts.table_name = opts.model.map((m) => m.toLowerCase());
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
  for (const [i, modelName] of opts.model.map(toPascalName).entries()) {
    await $`mkdir -p src/views/${modelName}`;
    for (const actionName of ["Form", "List", "Detail"]) {
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
