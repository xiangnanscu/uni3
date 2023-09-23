/* eslint-env node */
require("@rushstack/eslint-patch/modern-module-resolution");

module.exports = {
  root: true,
  globals: {
    globalThis: false,
    exec: "readonly",
    getCurrentPages: "readonly",
    uniCloud: "readonly",
    uni: "readonly",
    wx: "readonly",
    getApp: "readonly"
  },
  env: {
    node: true,
    amd: true
  },
  extends: [
    "./src/unplugin/.eslintrc-auto-import.json",
    "plugin:vue/vue3-essential",
    "eslint:recommended",
    "@vue/eslint-config-typescript",
    "@vue/eslint-config-prettier/skip-formatting"
  ],
  parserOptions: {
    ecmaVersion: "latest"
  },
  rules: {
    "max-len": [
      "warn",
      { code: 120, ignoreComments: true, ignoreStrings: false }
    ],
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
    "vue/multi-word-component-names": "off"
  }
};
