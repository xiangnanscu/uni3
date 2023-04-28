import { defineConfig } from "vite";
import uni from "@dcloudio/vite-plugin-uni";
import { readFileSync } from "fs";
import { fileURLToPath, URL } from "node:url";
import vue from "@vitejs/plugin-vue";
import vueJsx from "@vitejs/plugin-vue-jsx";
import AutoImport from "unplugin-auto-import/vite";
import Components from "unplugin-vue-components/vite";
import ViteRequireContext from "@originjs/vite-plugin-require-context";
import * as dotenv from "dotenv";

const dotenvExpand = require("dotenv-expand");

const importMode = process.env.NODE_ENV === "production" ? "sync" : "async";

const { parsed: exposedEnvs } = dotenvExpand.expand({
  ...dotenv.config({
    override: false,
    path: ".env",
  }),
  ignoreProcessEnv: true,
});

const env = process.env;
for (const key of Object.keys(env).sort()) {
  // console.log(key, env[key]);
}
const VITE_PROXY_PREFIX = process.env.VITE_PROXY_PREFIX || "/toXodel";
const VITE_PROXY_PREFIX_REGEX = new RegExp("^" + VITE_PROXY_PREFIX);
const VITE_APP_NAME = process.env.VITE_APP_NAME;
const PROD_URL = `https:${env.ALIOSS_URL}${VITE_APP_NAME}/`;

const baseUrl = env.NODE_ENV == "production" ? PROD_URL : "/";

const plugins = [
  uni(),
  Components({
    dirs: ["./src/components"],
    extensions: ["vue"],
    dts: "./src/unplugin/components.d.ts",
    directoryAsNamespace: true,
    resolvers: [],
  }),
  // vueJsx({
  //   // https://github.com/vuejs/babel-plugin-jsx
  //   // https://github.com/vitejs/vite/tree/main/packages/plugin-vue-jsx
  // }),
  AutoImport({
    //https://github.com/antfu/unplugin-auto-import#configuration
    eslintrc: {
      enabled: true, // Default `false`
      filepath: "./src/unplugin/.eslintrc-auto-import.json", // Default `./.eslintrc-auto-import.json`
      globalsPropValue: true, // Default `true`, (true | false | 'readonly' | 'readable' | 'writable' | 'writeable')
    },
    imports: [
      "vue",
      "pinia",
      "@vueuse/core",
    ],
    dts: "./src/unplugin/auto-imports.d.ts",
    vueTemplate: true,
    include: [
      /\.[tj]sx?$/, // .ts, .tsx, .js, .jsx
      /\.vue$/,
      /\.vue\?vue/, // .vue
    ],
    dirs: [
      "./src/components", // only root modules
      "./src/composables", // only root modules
      "./src/globals",
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
];
if (process.env.NODE_ENV == "production") {

}
const proxyServer = `http://${env.NGINX_server_name}:${env.NGINX_listen}`;
export default defineConfig({
  build: {
    minify: false,
  },
  assetsInclude: ["**/*.xlsx", "**/*.docx"],
  base: baseUrl,
  define: {
    "process.env": exposedEnvs,
  },
  plugins,
  optimizeDeps: {
    include: ["vue"],
  },
  resolve: {
    alias: {
      "@/": fileURLToPath(new URL("./src", import.meta.url)) + "/",
      stream: "stream-browserify",
      // vm: "vm-browserify",
      // buffer: "buffer/",
    },
  },
  css: {
    preprocessorOptions: {
      less: {
        javascriptEnabled: true,
      },
    },
  },
  // server: {
  //   // https://vitejs.dev/config/server-options.html#server-proxy
  //   // https://github.com/http-party/node-http-proxy#options
  //   port: Number(env.VITE_APP_PORT) || 5173,
  //   strictPort: true,
  //   proxy: {
  //     [VITE_PROXY_PREFIX]: {
  //       target: proxyServer,
  //       changeOrigin: true,
  //       rewrite: (path) => path.replace(VITE_PROXY_PREFIX_REGEX, ""),
  //     },
  //   },
  // },
});
