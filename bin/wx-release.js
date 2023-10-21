#!/usr/bin/env node

require("shelljs/global");
const os = require("os");
const ci = require("miniprogram-ci");
var path = require("path");
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

// console.log({ exposedEnvs });
// var keypath = path
//   .resolve("./conf/private.wxcec88a7e2c1e81c7.key")
//   .replaceAll("\\", "/");
// var description = process.argv[2] || "rc";
// var cmd;
// if (os.type() === "1Windows_NT") {
//   cmd = `cli publish --platform mp-weixin --project uni3 --upload true --appid wxcec88a7e2c1e81c7 --privatekey ${keypath} --description "${description}" --version ${version} --robot 1`;
// } else {
//   cmd = `miniprogram-ci upload --pp ./dist/build/mp-weixin --pkp ./conf/private.wxcec88a7e2c1e81c7.key --appid wxcec88a7e2c1e81c7 -r 1  --uv ${version}`;
// }

const desc = process.argv[2] || "update";
const project = new ci.Project({
  appid: exposedEnvs.WX_MINI_APPID,
  type: "miniProgram",
  projectPath: "./dist/build/mp-weixin",
  privateKeyPath: `./conf/private.${exposedEnvs.WX_MINI_APPID}.key`,
  ignores: ["node_modules/**/*"],
});

ci.upload({
  project,
  version: version,
  desc,
  setting: {
    es6: false,
    es7: false,
    minify: false,
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
