import "regenerator-runtime/runtime";
import { createSSRApp } from "vue";
import App from "./App.vue";
import { createPinia } from "pinia";
import uniSetup from "./uniSetup";
import { isLogin } from "@/lib/utils";

const pinia = createPinia();
const LOGIN_HINT = "login required";
const loginPage = process.env.UNI_LOGIN_PAGE;
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
      }
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
      }
    }
  });
  setTimeout(() => {
    app.config.errorHandler = (err, instance, info) => {
      console.error("errorHandler captured...", { err, instance, info });
      if (typeof err == "string") {
        uni.showModal({
          title: `错误`,
          content: err,
          showCancel: false
        });
      } else if (err.message == LOGIN_HINT) {
        utils.gotoPage({
          url: loginPage,
          query: { redirect: utils.getFullPath() },
          redirect: true
        });
      } else if (err.type == "uni_error") {
        uni.showModal({
          title: `错误`,
          content: err.message,
          showCancel: false
        });
      } else {
        console.error(err);
      }
    };
  });
  return {
    app
  };
}
