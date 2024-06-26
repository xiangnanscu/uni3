#!/usr/bin/env node

require("shelljs/global");
const ci = require("miniprogram-ci");
var { version } = require("../package.json");
const dotenv = require("dotenv");
const { expand } = require("dotenv-expand");

const { parsed: exposedEnvs } = expand({
  ...dotenv.config({
    override: false,
    path: ".env",
  }),
  ignoreProcessEnv: true,
});

const desc = process.argv[2] || "update";
const project = new ci.Project({
  appid: exposedEnvs.WX_MINI_APPID,
  type: "miniProgram",
  projectPath: "./dist/build/mp-weixin",
  privateKeyPath: `./conf/private.key`,
  ignores: ["node_modules/**/*"],
});

ci.upload({
  project,
  version: version,
  desc,
  setting: {
    // 经过一下午的反复实验,终于确定要设置为false
    es6: false,
    es7: false,
    minify: true,
  },
}).then((res) => {
  // eslint-disable-next-line no-undef
  console.log("upload success:\n", res);
  exec(`yarn push '${desc}'`, function (err, stdout, stderr) {
    if (err) {
      console.log("seems err:", err, {
        stdout,
        stderr,
      });
      throw new Error(err);
    }
    console.log(stdout);
  });
});
