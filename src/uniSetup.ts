import cookie from "cookie";
import { useStore } from "@/store";
import { useSession } from "@/store/session";

const viteEnv = import.meta.env;
// console.log("uni.getSystemInfo", uni.getSystemInfoSync());
const platform = uni.getSystemInfoSync().uniPlatform;
const isWeb = platform == "web" || platform == "h5";
const baseURL =
  process.env.NODE_ENV == "production"
    ? `${viteEnv.VITE_HTTPS == "on" ? "https" : "http"}://${viteEnv.VITE_HOST}`
    : isWeb
    ? `http://localhost:${viteEnv.VITE_APP_PORT}${viteEnv.VITE_PROXY_PREFIX}`
    : `http://localhost:${process.env.NGINX_listen}`;
const cookieNames = ["session"];

const setupRequest = () => {
  uni.addInterceptor("request", {
    invoke(args) {
      // console.log("global uni.request invoke:", args);
      const store = useStore();
      if (!store.disableLoading) {
        store.loading = true;
        uni.showLoading();
      }
      const header = args.header || {};
      // #ifdef MP-WEIXIN
      for (const cookieName of cookieNames) {
        const cookieStr = uni.getStorageSync(`cookie_${cookieName}`);
        if (cookieStr) {
          if (header.cookie) {
            header.cookie = `${header.cookie};${cookieName}=${cookieStr}`;
          } else {
            header.cookie = `${cookieName}=${cookieStr}`;
          }
        }
      }
      // #endif
      header["Uni-Request"] = "on";
      args.header = header;
      if (!/^https?|^\/\//.test(args.url)) args.url = baseURL + args.url;
    },
    success({ data, statusCode, header, cookies }) {
      // 微信小程序任何code都算成功
      // console.log({ cookies, header });
      if (statusCode < 600 && statusCode >= 500) {
        uni.showToast({
          icon: "none",
          title: `发生错误`,
          duration: 5000
        });
      }
    },
    fail(err) {
      console.log("global uni.request fail:", err);
    },
    complete(args) {
      // console.log("global uni.request complete:", args);
      const store = useStore();
      store.loading = false;
      uni.hideLoading();
      const cookies = args.cookies || [];
      // #ifdef H5
      if (cookies.length === 0 && args.header["set-cookie-patch"]) {
        cookies.push(...args.header["set-cookie-patch"].split(", "));
      }
      // #endif
      for (const cookieStr of cookies) {
        const c = cookie.parse(cookieStr);
        for (const cookieName of cookieNames) {
          if (c[cookieName]) {
            uni.setStorageSync(`cookie_${cookieName}`, c[cookieName]);
            break;
          }
        }
      }
    }
  });
};

const navHandlerList = ["navigateTo", "redirectTo", "reLaunch", "switchTab"];
const loginPage = process.env.UNI_LOGIN_PAGE;
const whiteList = [
  process.env.UNI_HOME_PAGE,
  loginPage,
  "/pages/LoginH5",
  "/pages/LoginWx",
  "/pages/tabbar/ProfileMy"
];

const navStack: number[] = [];
const setupNav = () => {
  navHandlerList.forEach((handler) => {
    uni.addInterceptor(handler, {
      invoke(opts) {
        console.log("路由拦截", handler, opts.url);
        navStack.push(new Date().getTime());
        const { message, error, loading } = storeToRefs(useStore());
        message.value = "";
        error.value = "";
        const [url, qs] = opts.url.split("?");
        if (whiteList.includes(url)) {
          console.log("路由拦截-白名单", url, JSON.stringify(opts));
          return opts;
        }
        const sessionCookie = uni.getStorageSync("cookie_session");
        const { session } = useSession();
        if (sessionCookie && session?.user?.id) {
          return opts;
        }
        const loginUrl = `${loginPage}?redirect=${encodeURIComponent(
          opts.url
        )}`;
        console.log("路由拦截-需要登陆", opts.url);
        uni.redirectTo({ ...opts, url: loginUrl });
        return false;
      },
      complete(res) {
        console.log("路由拦截结束", res);
        navStack.pop();
      },
      fail(err) {
        // 失败回调拦截
        console.error("路由拦截失败", err);
      }
    });
  });
};

export default () => {
  setupRequest();
  setupNav();
};