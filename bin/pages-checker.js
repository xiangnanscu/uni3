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
const fileList = readDir("src/pages").map((file) =>
  file.replaceAll(/\\/g, "/").slice(4, -4)
);
for (const url of fileList) {
  const page = pages.pages.find((e) => e.path == url);
  if (!page) {
    pages.pages.push({ path: url, style: { navigationBarTitleText: "" } });
  }
}
const exitstedPages = [];
for (const page of pages.pages) {
  const findPage = fileList.find((url) => url == page.path);
  if (findPage) {
    exitstedPages.push(page);
  } else {
    console.log(`remove page ${page.path} from pages.json`);
  }
}
pages.pages = exitstedPages;
const pageJson = JSON.stringify(pages);
const formatedJson = prettier.format(pageJson, { parser: "json" });

fs.writeFileSync("src/pages.json", formatedJson);
