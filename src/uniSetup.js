import cookie from "cookie";
import { useStore } from "@/store";
import { version } from "../package.json";
import { isLogin } from "@/lib/utils";

const viteEnv = import.meta.env;

let baseURL;
if (process.env.NODE_ENV == "production") {
  baseURL = `${viteEnv.VITE_HTTPS == "on" ? "https" : "http"}://${viteEnv.VITE_HOST}`;
} else {
  // #ifdef H5
  baseURL = `http://localhost:${viteEnv.VITE_APP_PORT}${viteEnv.VITE_PROXY_PREFIX}`;
  // #endif
  // #ifdef MP-WEIXIN
  baseURL = `http://localhost:${process.env.NGINX_listen}`;
  // #endif
}

const cookieNames = ["session"];

const setupRequest = () => {
  uni.addInterceptor("request", {
    invoke(args) {
      // console.log("global uni.request invoke:", args);
      const store = useStore();
      store.loading = true;
      store.message = "";
      store.error = "";
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
      header["X-Version"] = version;
      args.header = header;
      if (!/^https?|^\/\//.test(args.url)) args.url = baseURL + args.url;
    },
    success(args) {
      // args.statusCode居然直接丢失了..
      // console.log("success", args);
    },
    fail(err) {
      console.log("global uni.request fail:", err);
    },
    complete(args) {
      // console.log("global uni.request complete:", args);
      const store = useStore();
      store.loading = false;
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
    },
  });
};

const navHandlerList = ["navigateTo", "redirectTo", "switchTab"];
const loginPage = process.env.UNI_LOGIN_PAGE;
const realNameCertPage = "/views/RealNameCert";
const whiteList = [
  "/",
  process.env.UNI_HOME_PAGE,
  loginPage,
  "/views/tabbar/ProfileMy",
  "/views/AdDetail",
  "/views/NewsDetail",
  "/views/ThreadDetail",
  "/views/GoddessDetail",
  // "/views/PollDetail",
  "/views/StageDetail",
  "/views/VolplanDetail",
];
const realNameCertList = [
  "/views/SchoolPrincipalRegedit",
  "/views/SchoolStudentRegedit",
  "/views/SchoolTeacherRegedit",
  "/views/FeeplanList",
  "/views/ShykDetail",
  "/views/ForumAdd",
  "/views/GoddessAdd",
  "/views/StageDetail",
  "/views/VolAdd",
  "/views/VolplanDetail",
];

const navStack = [];
const setupNav = () => {
  navHandlerList.forEach((handler) => {
    uni.addInterceptor(handler, {
      invoke(opts) {
        console.log("路由拦截", handler, opts);
        navStack.push(new Date().getTime());
        const { message, error } = storeToRefs(useStore());
        message.value = "";
        error.value = "";
        const [url, qs] = opts.url.split("?");
        if (whiteList.includes(url)) {
          // console.log("路由拦截-白名单", url, JSON.stringify(opts));
          return opts;
        }
        const user = useUser();
        // 首先检测是否需要登录
        if (!user.id) {
          utils.gotoPage({
            url: loginPage,
            query: { redirect: opts.url },
            redirect: true,
          });
          return false;
        }
        // 再检测是否需要实名
        if (!user.username && realNameCertList.includes(url)) {
          console.log("需要实名:", opts.url);
          utils.gotoPage({
            url: realNameCertPage,
            query: { redirect: opts.url, message: "此操作需要先实名认证" },
            redirect: true,
          });
          return false;
        }
        return opts;
      },
      complete(res) {
        // console.log("路由拦截结束", res);
        navStack.pop();
      },
      fail(err) {
        // 失败回调拦截
        console.error("路由拦截失败", err);
      },
    });
  });
};

export default () => {
  setupRequest();
  setupNav();
};
