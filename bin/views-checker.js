#!/usr/bin/env node
const prettier = require("prettier");
const fs = require("fs");
const path = require("path");
const views = require("../src/views.json");

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
const fileList = readDir("src/views").map((file) =>
  file.replaceAll(/\\/g, "/").slice(4, -4)
);
for (const url of fileList) {
  const page = views.views.find((e) => e.path == url);
  if (!page) {
    views.views.push({ path: url, style: { navigationBarTitleText: "" } });
  }
}
const exitstedPages = [];
for (const page of views.views) {
  const findPage = fileList.find((url) => url == page.path);
  if (findPage) {
    exitstedPages.push(page);
  } else {
    console.log(`remove page ${page.path} from views.json`);
  }
}
views.views = exitstedPages;
const pageJson = JSON.stringify(views);
const formatedJson = prettier.format(pageJson, { parser: "json" });

fs.writeFileSync("src/views.json", formatedJson);
