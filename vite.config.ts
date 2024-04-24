import { readFileSync } from "fs";
import { defineConfig } from "vite";
import uni from "@dcloudio/vite-plugin-uni";
import * as dotenv from "dotenv";
import { expand } from "dotenv-expand";
import AutoImport from "unplugin-auto-import/vite";
import Components from "unplugin-vue-components/vite";
import { fileURLToPath, URL } from "node:url";
import ViteRequireContext from "@originjs/vite-plugin-require-context";

const env = process.env;
const plugins = [
  Components({
    // https://github.com/antfu/unplugin-vue-components#configuration
    dirs: ["./src/components"],
    extensions: ["vue", "jsx"],
    dts: "./src/unplugin/components.d.ts",
    directoryAsNamespace: true,
    resolvers: [],
  }),
  AutoImport({
    //https://github.com/antfu/unplugin-auto-import#configuration
    defaultExportByFilename: true,
    eslintrc: {
      enabled: true, // Default `false`
      filepath: "./src/unplugin/.eslintrc-auto-import.json", // Default `./.eslintrc-auto-import.json`
      globalsPropValue: true, // Default `true`, (true | false | 'readonly' | 'readable' | 'writable' | 'writeable')
    },
    imports: [
      "vue",
      "pinia",
      "@vueuse/core",
      {
        "@dcloudio/uni-app": [
          "onLoad",
          "onShow",
          "onReady",
          "onHide",
          "onUnload",
          "onShareTimeline",
          "onAddToFavorites",
          "onReachBottom",
          "onShareAppMessage",
        ],
        "regenerator-runtime": [["default", "regeneratorRuntime"]],
      },
    ],
    dts: "./src/unplugin/auto-imports.d.ts",
    vueTemplate: true,
    include: [/\.[tj]sx?$/, /\.vue$/, /\.vue\?vue/],
    dirs: [
      "./src/globals",
      "./src/composables", // only root modules
      "./src/store/**", // all nested modules
    ],
  }),
  // https://docs.sheetjs.com/docs/demos/static/vitejs
  {
    // this plugin handles ?b64 tags
    name: "vite-b64-plugin",
    transform(code, id) {
      if (!id.match(/\?b64$/)) return;
      // console.log(id, code);
      const path = id.replace(/\?b64/, "");
      const data = readFileSync(path, "base64");
      return `export default '${data}'`;
    },
  },
  {
    // https://stackoverflow.com/questions/21797299/convert-base64-string-to-arraybuffer
    name: "vite-office-plugin",
    transform(code, id) {
      if (!id.match(/\.(xlsx|docx|zip)$/)) return;
      const path = id;
      const data = readFileSync(path, "base64");
      return `export default Uint8Array.from(atob('${data}'), (c) => c.charCodeAt(0))`;
    },
  },
  ViteRequireContext(),
  uni({
    vueOptions: {},
    vueJsxOptions: {},
  }),
];
const toLiteral = (s) => `"${s.replaceAll(/"/g, '\\"')}"`;
const { parsed: exposedEnvs } = expand({
  ...dotenv.config({
    override: false,
    path: ".env",
  }),
  ignoreProcessEnv: true,
});
const envKeys = Object.fromEntries(
  Object.entries(exposedEnvs).map(([k, v]) => [`process.env.${k}`, toLiteral(v)]),
);
const VITE_PROXY_PREFIX = process.env.VITE_PROXY_PREFIX || "/proxy";
const VITE_PROXY_PREFIX_REGEX = new RegExp("^" + VITE_PROXY_PREFIX);
const VITE_NAME = process.env.VITE_NAME;
// https://vitejs.dev/config/
export default defineConfig({
  plugins,
  define: envKeys,
  optimizeDeps: {
    // include: ["vue"],
  },
  resolve: {
    alias: {
      "@/": fileURLToPath(new URL("./src", import.meta.url)) + "/",
      stream: "stream-browserify",
      // vm: "vm-browserify",
      // Buffer: "buffer/",
    },
  },
  css: {
    preprocessorOptions: {
      less: {
        javascriptEnabled: true,
      },
    },
  },
  // #ifdef H5
  server: {
    // https://vitejs.dev/config/server-options.html#server-proxy
    // https://github.com/http-party/node-http-proxy#options
    port: Number(env.VITE_PORT),
    strictPort: true,
    proxy: {
      [VITE_PROXY_PREFIX]: {
        target: `http://${env.NGINX_server_name}:${env.NGINX_listen}`,
        changeOrigin: true,
        rewrite: (path) => path.replace(VITE_PROXY_PREFIX_REGEX, ""),
      },
    },
  },
  // #endif
});
