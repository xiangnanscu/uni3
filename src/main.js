import "regenerator-runtime/runtime";
import { createSSRApp } from "vue";
import App from "./App.vue";
import uniSetup from "./uniSetup";
import { isLogin, globalErrorHandler } from "~/lib/helpers.js";
import { Model } from "~/lib/model/model.mjs";
import { BaseField } from "~/lib/model/field.mjs";
import { request } from "~/lib/Http";
import { useSession } from "~/composables/useSession";

const LOGIN_HINT = "login required";
Model.request = request;
BaseField.request = request;
globalThis.log = console.log;

export function createApp() {
  uniSetup();
  const app = createSSRApp(App);
  app.mixin({
    computed: {
      user() {
        const session = useSession();
        return session.user;
      },
    },
    methods: {
      checkLogin() {
        if (!isLogin()) {
          throw new Error(LOGIN_HINT);
        }
      },
      previewImage(url) {
        if (url.startsWith("//")) {
          url = "https:" + url;
        } else if (url.startsWith("http:")) {
          url = `https:${url.slice(5)}`;
        }
        uni.previewImage({ urls: [url], current: 0 });
      },
    },
  });
  setTimeout(() => {
    app.config.errorHandler = globalErrorHandler;
  });
  return {
    app,
  };
}
