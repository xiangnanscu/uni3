#!/usr/bin/env node
const prettier = require("prettier");
const fs = require("fs");
const path = require("path");
const pages = require("../src/pages.json");

function readDir(dir, fileList) {
  const files = fs.readdirSync(dir);

  fileList = fileList || [];

  files.forEach((file) => {
    const filePath = path.join(dir, file);

    if (fs.statSync(filePath).isDirectory()) {
      fileList = readDir(filePath, fileList);
    } else {
      if (path.extname(filePath) === ".vue") {
        fileList.push(filePath);
      }
    }
  });

  return fileList;
}
const fileList = readDir("src/pages");
for (const file of fileList) {
  const url = file.replaceAll(/\\/g, "/").slice(4, -4);
  const page = pages.pages.find((e) => e.path == url);
  if (!page) {
    pages.pages.push({ path: url, style: { navigationBarTitleText: "" } });
  }
}
const pageJson = JSON.stringify(pages);
const formatedJson = prettier.format(pageJson, { parser: "json" });

fs.writeFileSync("src/pages.json", formatedJson);
