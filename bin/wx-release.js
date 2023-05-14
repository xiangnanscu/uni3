#!/usr/bin/env node
require("shelljs/global");
// var exec = require('child_process').exec;
var path = require("path");
var { version } = require("../package.json");

var keypath = path
  .resolve("./conf/private.wxcec88a7e2c1e81c7.key")
  .replaceAll("\\", "/");
var description = process.argv[2] || "nothing";
var cmd = `cli publish --platform mp-weixin --project jaqn-mini --upload true --appid wxcec88a7e2c1e81c7 --privatekey ${keypath} --description "${description}" --version ${version}`;
console.log("路径:", cmd);

// eslint-disable-next-line no-undef
exec(cmd, function (err, stdout, stderr) {
  if (err) {
    console.log("seems err:", err, { stdout, stderr });
    throw new Error(err);
  }
  console.log("stdout", JSON.stringify(stdout));
});
