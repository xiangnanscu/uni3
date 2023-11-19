import "regenerator-runtime/runtime";
import { createSSRApp } from "vue";
import App from "./App.vue";
import { createPinia } from "pinia";
import uniSetup from "./uniSetup";
import { isLogin, NeedLoginError, NeedRealNameError } from "@/lib/helpers.js";
import { Model } from "@/lib/model/model.mjs";
import { basefield } from "@/lib/model/field.mjs";
import { getFullPath } from "@/lib/utils";
import Http from "@/globals/Http.js";

Model.Http = Http;
basefield.Http = Http;
const pinia = createPinia();
const LOGIN_HINT = "login required";
const loginPage = process.env.UNI_LOGIN_PAGE;
globalThis.log = console.log;
// https://pinia.vuejs.org/core-concepts/plugins.html#adding-new-external-properties
// pinia.use(({ store }) => {
//   store.router = markRaw(router);
// });
export function createApp() {
  uniSetup();
  const app = createSSRApp(App);
  app.use(pinia);
  app.mixin({
    computed: {
      user() {
        const { session } = useSession();
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
    app.config.errorHandler = (err, instance, info) => {
      // console.error("errorHandler captured...", err, { instance, info });
      if (err instanceof NeedLoginError || err.message == LOGIN_HINT) {
        console.log("NeedLoginError需要登录");
        utils.redirect(loginPage, {
          message: "此操作需要登录",
          redirect: utils.getSafeRedirect(getFullPath()),
        });
      } else if (err instanceof NeedRealNameError) {
        console.log("NeedRealNameError需要实名认证");
        utils.redirect("/views/RealNameCert", {
          message: "此操作需要登录",
          redirect: utils.getSafeRedirect(getFullPath()),
        });
      } else if (typeof err == "string") {
        uni.showModal({
          title: `错误`,
          content: err,
          showCancel: false,
        });
      } else if (err.type == "uni_error") {
        uni.showModal({
          title: `错误`,
          content: err.message,
          showCancel: false,
        });
      } else {
        console.error(err);
      }
    };
  });
  return {
    app,
  };
}
