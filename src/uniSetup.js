import cookie from "cookie";
import { useStore } from "~/composables/useStore";
import { version } from "../package.json";

const viteEnv = import.meta.env;

function countOccurrences(string, character) {
  let count = 0;
  for (const e of string) {
    if (e === character) {
      count++;
    }
  }
  return count;
}
let baseURL;
if (process.env.NODE_ENV == "production") {
  baseURL = `${viteEnv.VITE_HTTPS == "on" ? "https" : "http"}://${viteEnv.VITE_HOST}`;
} else {
  // #ifdef H5
  baseURL = `http://localhost:${viteEnv.VITE_PORT}${viteEnv.VITE_PROXY_PREFIX}`;
  // #endif
  // #ifdef MP-WEIXIN
  baseURL = `http://localhost:${process.env.NGINX_listen}`;
  // #endif
}

const cookieNames = ["session"];

const setupRequest = () => {
  uni.addInterceptor("request", {
    invoke(args) {
      const store = useStore();
      const showLoading = !args?.disableLoading && !store.disableLoading.value;
      store.loading.value = true;
      store.message.value = "";
      store.error.value = "";
      const header = args.header || {};
      if (showLoading) {
        uni.showLoading();
      }
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
      if (!/^https?|^\/\//.test(args.url)) {
        args.url = baseURL + args.url;
      }
      console.log("global uni.request invoke:", typeof args, args);
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
      const showLoading = !args?.disableLoading && !store.disableLoading.value;
      if (showLoading) {
        uni.hideLoading();
      }
      store.loading.value = false;
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
const UNI_LOGIN_PAGE = process.env.UNI_LOGIN_PAGE;
const REAL_NAME_CERT_PAGE = "/views/RealNameCert";
const whiteList = [
  "/",
  process.env.UNI_HOME_PAGE,
  UNI_LOGIN_PAGE,
  "/views/tabbar/ProfileMy",
  "/views/AdDetail",
  "/views/NewsDetail",
  "/views/ThreadDetail",
  "/views/GoddessDetail",
  // "/views/PollDetail",
  "/views/StageDetail",
  "/views/VolplanDetail",
  "/views/LuckyWheel",
  "/views/RealNameCert",
];
const realNameCertList = [
  "/views/SchoolRegeditParentChild",
  "/views/SchoolRegeditPrincipal",
  "/views/SchoolRegeditClassDirector",
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
const setupNav = () => {
  navHandlerList.forEach((handler) => {
    uni.addInterceptor(handler, {
      invoke(opts) {
        console.log("**路由拦截:", handler, opts.url);
        const { message, error } = useStore();
        message.value = "";
        error.value = "";
        const [route_path, ...qs] = opts.url.split("?");
        // console.log("nav split:", { url, qs });
        if (whiteList.includes(route_path)) {
          return opts;
        }
        const user = useUser();
        // 首先检测是否需要登录
        if (!user.id) {
          console.log("**需要登录的URL:", route_path);
          utils.redirect(UNI_LOGIN_PAGE, {
            message: "此操作需要登录",
            redirect: utils.getSafeRedirect(opts.url),
          });
          return false;
        }
        // 再检测是否需要实名
        if (!user.username && realNameCertList.includes(route_path)) {
          console.log("**需要实名的URL:", opts.url);
          utils.redirect(REAL_NAME_CERT_PAGE, {
            message: "此操作需要实名认证",
            redirect: utils.getSafeRedirect(opts.url),
          });
          return false;
        }
        if (countOccurrences(opts.url, "?") === 2) {
          console.log("**检测到2个问号需调用utils.getSafeRedirect");
          opts.url = utils.getSafeRedirect(opts.url);
          return opts;
        } else {
          return opts;
        }
      },
      complete(res) {
        // console.log("路由拦截结束", res);
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
