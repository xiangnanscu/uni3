import cookie from "cookie";
import { useStore } from "@/store";

const viteEnv = import.meta.env;
const baseURL =
  process.env.NODE_ENV == "production"
    ? `${viteEnv.VITE_HTTPS == "on" ? "https" : "http"}://${viteEnv.VITE_HOST}`
    : `http://localhost:${process.env.NGINX_listen}`;
const cookieNames = ["session"];

uni.addInterceptor("request", {
  invoke(args) {
    console.log("global uni.request invoke:", args);
    const store = useStore();
    if (!store.disableLoading) {
      store.loading = true;
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
    console.log("global uni.request success:", {
      data,
      statusCode,
      header,
      cookies,
    });
    if (statusCode < 600 && statusCode >= 500) {
      uni.showToast({
        icon: "none",
        title: `发生错误`,
        duration: 5000,
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
    for (const cookieStr of args.cookies) {
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

class Http {
  static async get(url, opts) {
    return await uni.request({
      url,
      method: "get",
      ...opts,
    });
  }

  static async post(url, data, opts) {
    return await uni.request({
      url,
      data,
      method: "post",
      ...opts,
    });
  }
}

export { Http };
export { Http as $Http };
