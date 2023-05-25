import { createSSRApp } from "vue";
import App from "./App.vue";
import { createPinia } from "pinia";

const pinia = createPinia();

const navHandlerList = ["navigateTo", "redirectTo", "reLaunch", "switchTab"];
const loginPage = process.env.UNI_LOGIN_PAGE;
const whiteList = [process.env.UNI_HOME_PAGE, loginPage];

const lock: number[] = [];
navHandlerList.forEach((handler) => {
  uni.addInterceptor(handler, {
    invoke(opts) {
      lock.push(new Date().getTime());
      console.log("路由拦截", utils.repr(lock), handler, opts.url);
      const { message, error, loading } = storeToRefs(useStore());
      message.value = "";
      error.value = "";
      const [url, qs] = opts.url.split("?");
      if (whiteList.includes(url)) {
        console.log("路由拦截-白名单", url, JSON.stringify(opts));
        return;
      }
      const sessionCookie = uni.getStorageSync("cookie_session");
      const { session } = useSession();
      if (sessionCookie && session?.user?.id) {
        return;
      }
      const loginUrl = `${loginPage}?redirect=${encodeURIComponent(url)}`;
      console.log(
        "路由拦截-需要登陆",
        opts.url,
        JSON.stringify({ session, sessionCookie })
      );
      // 这里return false间歇性报错, return opts会保持当前路由达不到拦截的效果
      // 这里是否需要await呢
      uni.navigateTo({ url: loginUrl });
      return;
    },
    complete(res) {
      console.log("路由拦截结束", utils.repr(lock), res);
      lock.pop();
    },
    fail(err) {
      // 失败回调拦截
      console.error("路由拦截失败", utils.repr(lock), err);
    }
  });
});

// https://pinia.vuejs.org/core-concepts/plugins.html#adding-new-external-properties
// pinia.use(({ store }) => {
//   store.router = markRaw(router);
// });
export function createApp() {
  const app = createSSRApp(App);
  app.use(pinia);
  app.mixin({
    computed: {
      user() {
        const { session } = useSession();
        return session.user;
      }
    }
  });
  return {
    app
  };
}
