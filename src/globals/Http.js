import { NeedLoginError, globalErrorHandler } from "@/lib/helpers.js";

class WxResquestError extends Error {
  constructor({ type, status, data }) {
    super(data);
    this.type = type;
    this.status = status;
    this.data = data;
  }
}

const throwOnUniError = (response) => {
  const data = response.data;
  if (typeof data == "object" && data.type == "uni_error") {
    log("throwOnUniError", data);
    if (data.status === 403) {
      console.log("权限不足，需要登陆");
      throw new NeedLoginError();
    } else if (data.status >= 500) {
      globalErrorHandler(data);
    } else if (data.status === 404) {
      globalErrorHandler(data);
    } else {
      globalErrorHandler(data);
    }
  } else {
    return response;
  }
};

class Http {
  static async get(url, data, opts) {
    const response = await uni.request({
      url,
      data: data || {},
      method: "get",
      foo: "bar",
      ...opts,
    });
    return throwOnUniError(response);
  }

  static async post(url, data, opts) {
    const response = await uni.request({
      url,
      data: data || {},
      method: "post",
      ...opts,
    });
    return throwOnUniError(response);
  }
}

export default Http;
