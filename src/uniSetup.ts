import cookie from "cookie";
import { useStore } from "@/store";
import { useSession } from "@/store/session";

const viteEnv = import.meta.env;
const baseURL =
  process.env.NODE_ENV == "production"
    ? `${viteEnv.VITE_HTTPS == "on" ? "https" : "http"}://${viteEnv.VITE_HOST}`
    : `http://localhost:${process.env.NGINX_listen}`;
const cookieNames = ["session"];

const setupRequest = () => {
  uni.addInterceptor("request", {
    invoke(args) {
      console.log("global uni.request invoke:", args);
      const store = useStore();
      if (!store.disableLoading) {
        store.loading = true;
        uni.showLoading();
      }
      const header = args.header || {};
      for (const cookieName of cookieNames) {
        const cookieStr = uni.getStorageSync(`cookie_${cookieName}`);
        if (cookieStr) {
          if (header.cookie) {
            header.cookie = `${header.cookie};${cookieName}=${cookieStr}`;
          } else {
            header.cookie = `session=${cookieStr}`;
          }
        }
      }
      args.header = header;
      if (!/^https?|^\/\//.test(args.url)) args.url = baseURL + args.url;
    },
    success({ data, statusCode, header, cookies }) {
      console.log("success", { statusCode });
      // console.log("global uni.request success:", {
      //   data,
      //   statusCode,
      //   header,
      //   cookies
      // });
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
      console.log("global uni.request complete:", args);
      const store = useStore();
      store.loading = false;
      uni.hideLoading();
      for (const cookieStr of args.cookies || []) {
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
        const loginUrl = `${loginPage}?redirect=${encodeURIComponent(url)}`;
        console.log(
          "路由拦截-需要登陆",
          opts.url,
          JSON.stringify({ session, sessionCookie })
        );
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
