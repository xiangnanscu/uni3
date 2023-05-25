import { createSSRApp } from "vue";
import App from "./App.vue";
import { createPinia } from "pinia";

const pinia = createPinia();


const navHandlerList = ["navigateTo", "redirectTo", "reLaunch", "switchTab"];
const loginPage = process.env.UNI_LOGIN_PAGE;
const whiteList = [process.env.UNI_HOME_PAGE, loginPage];

function get_session() {
  try {
    return JSON.parse(uni.getStorageSync("session"));
  } catch (error) {
    return {};
  }
}
navHandlerList.forEach((handler) => {
  uni.addInterceptor(handler, {
    async invoke(opts) {
      console.log("路由拦截", handler, opts.url);
      const { message, error, loading } = storeToRefs(useStore());
      message.value = ""
      error.value = ""
      const [url, qs] = opts.url.split("?");
      if (whiteList.includes(url)) {
        return opts;
      }
      const sessionCookie = uni.getStorageSync("cookie_session");
      const session = get_session();
      if (sessionCookie && session?.user?.id) {
        return opts;
      }
      // console.log("路由拦截-需要登陆", opts.url, { session, sessionCookie });
      // 这里return false间歇性报错, return opts会保持当前路由达不到拦截的效果
      return uni.navigateTo({
        // 这里是否需要await呢
        url: `${loginPage}?redirect=${encodeURIComponent(url)}`,
      });
    },
    complete(res) {
      console.log("this.$store");
    },
    fail(err) {
      // 失败回调拦截
      console.log("路由拦截失败", err);
    },
  });
});


// https://pinia.vuejs.org/core-concepts/plugins.html#adding-new-external-properties
// pinia.use(({ store }) => {
//   store.router = markRaw(router);
// });
export function createApp() {
  const app = createSSRApp(App);
  app.use(pinia);
  return {
    app,
  };
}
