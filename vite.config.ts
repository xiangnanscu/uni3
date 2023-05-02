import { defineConfig } from "vite";
import uni from "@dcloudio/vite-plugin-uni";
import * as dotenv from "dotenv";
import { expand } from "dotenv-expand";

const { parsed: exposedEnvs } = expand({
  ...dotenv.config({
    override: false,
    path: ".env",
  }),
  ignoreProcessEnv: true,
});

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [uni()],
  define: {
    "process.env": exposedEnvs,
  },
});
