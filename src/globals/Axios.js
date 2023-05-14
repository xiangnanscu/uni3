import axios from "axios";
import { useMyStore } from "@/store/store.ts";

const viteEnv = import.meta.env;
// console.log("import.meta.env1", viteEnv, process.env.NODE_ENV);
const baseURL =
  process.env.NODE_ENV == "production"
    ? `${viteEnv.VITE_HTTPS == "on" ? "https" : "http"}://${viteEnv.VITE_HOST}`
    : `http://localhost:${viteEnv.VITE_APP_PORT}${viteEnv.VITE_PROXY_PREFIX}`;
const instance = axios.create({
  baseURL,
  timeout: 100000, // 小心,如果设置得太短了, Axios会主动cancel请求, 有可能nginx仍在处理此请求后续成功,但前端认为没有成功
  // headers: { "X-Custom-Header": "foobar" },
});

// Add a request interceptor
instance.interceptors.request.use(
  function (config) {
    // console.log("Do something before request is sent", config);
    const store = useMyStore();
    store.loading = true;
    return config;
  },
  function (error) {
    // Do something with request error
    return Promise.reject(error);
  }
);

// Add a response interceptor
instance.interceptors.response.use(
  function (response) {
    // Any status code that lie within the range of 2xx cause this function to trigger
    // Do something with response data
    const store = useMyStore();
    store.loading = false;
    return response;
  },
  function (error) {
    // Any status codes that falls outside the range of 2xx cause this function to trigger
    // Do something with response error
    const store = useMyStore();
    store.loading = false;
    if (error.response.status == 403) {
      return store.router.push({
        name: "UserLogin",
        query: {
          redirect: store.router.currentRoute.value.fullPath,
          // r2: router2.currentRoute.value.fullPath, // 永远是'/'
        },
      });
    }
    return Promise.reject(error);
  }
);

class Axios {
  static async post(url, data, config) {
    return await instance({
      url,
      data,
      method: "POST",
      headers: { "X-Requested-With": "XMLHttpRequest" },
      params: {
        t: new Date().getTime(),
      },
      responseType: "json", // 'arraybuffer', 'document', 'json', 'text', 'stream','blob'
      responseEncoding: "utf8",
      ...config,
    });
  }
  static async get(url, config) {
    return await instance({
      url,
      method: "GET",
      headers: { "X-Requested-With": "XMLHttpRequest" },
      params: {
        t: new Date().getTime(),
      },
      responseType: "json", // 'arraybuffer', 'document', 'json', 'text', 'stream','blob'
      responseEncoding: "utf8",
      ...config,
    });
  }
}

export { Axios, Axios as axios };
