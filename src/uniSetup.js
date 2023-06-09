import cookie from "cookie";
import { useStore } from "@/store";
import { useSession } from "@/store/session";

const viteEnv = import.meta.env;

let baseURL;
if (process.env.NODE_ENV == "production") {
  baseURL = `${viteEnv.VITE_HTTPS == "on" ? "https" : "http"}://${
    viteEnv.VITE_HOST
  }`;
} else {
  // #ifdef H5
  baseURL = `http://localhost:${viteEnv.VITE_APP_PORT}${viteEnv.VITE_PROXY_PREFIX}`;
  // #endif
  // #ifdef MP-WEIXIN
  baseURL = `http://localhost:${process.env.NGINX_listen}`;
  // #endif
}

const cookieNames = ["session"];

class WxResquestError extends Error {
  constructor({ type, status, data }) {
    super(data);
    this.type = type;
    this.status = status;
  }
}
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
    success(args) {
      // args.statusCode居然直接丢失了..
      // console.log("success", args);
      const data = args.data;
      if (typeof data == "object" && data.type == "uni_error") {
        if (data.status === 403) {
          utils.gotoPage({
            url: process.env.UNI_LOGIN_PAGE,
            query: { redirect: getCurrentPages().slice(-1)[0].$page?.fullPath }
          });
        } else {
          // success里面抛异常会导致modelform的try-catch失效
          // throw new WxResquestError(data);
        }
      }
    },
    fail(err) {
      console.log("global uni.request fail:", err);
    },
    complete(args) {
      // console.log("global uni.request complete:", args);
      const store = useStore();
      store.loading = false;
      if (!store.disableLoading) {
        store.loading = false;
        uni.hideLoading();
      }
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

const navHandlerList = ["navigateTo", "redirectTo"];
const loginPage = process.env.UNI_LOGIN_PAGE;
const whiteList = [
  process.env.UNI_HOME_PAGE,
  loginPage,
  "/pages/LoginH5",
  "/pages/LoginWx",
  "/pages/tabbar/ProfileMy"
];

const navStack = [];
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
        uni.navigateTo({
          ...opts,
          url: loginUrl
        });
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
