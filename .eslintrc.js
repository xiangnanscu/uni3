/* eslint-env node */
require("@rushstack/eslint-patch/modern-module-resolution");

module.exports = {
  root: true,
  env: {
    exec: "readonly",
    getCurrentPages: "readonly",
    uniCloud: "readonly",
    uni: "readonly",
    wx: "readonly",
    getApp: "readonly"
  },
  globals: {
    uni: true,
    wx: true
  },
  rules: {
    "prefer-const": [
      "error",
      {
        destructuring: "all",
        ignoreReadBeforeAssign: false
      }
    ],
    "vue/no-unused-vars": [
      "warn",
      {
        ignorePattern: "^_"
      }
    ],
    "no-unused-vars": [
      "warn",
      { vars: "all", args: "after-used", argsIgnorePattern: "^_" }
    ],
    "vue/no-dupe-keys": "off", // 出了bug,先取消
    "vue/multi-word-component-names": "off",
    "vue/no-setup-props-destructure": "off"
  },
  extends: [
    // 这里必须以./开头,否则不会被识别为文件路径
    "./src/unplugin/.eslintrc-auto-import.json",
    "plugin:vue/vue3-essential",
    "eslint:recommended",
    "@vue/eslint-config-typescript",
    "@vue/eslint-config-prettier/skip-formatting"
    // "@vue/eslint-config-prettier",
  ],
  parserOptions: {
    ecmaVersion: "latest"
    // parserOptions: { tsconfigRootDir: __dirname }
  }
};
