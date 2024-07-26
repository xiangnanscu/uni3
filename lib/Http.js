import { NeedLoginError, globalErrorHandler } from "~/lib/helpers.js";

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
    // console.log("throwOnUniError", data);
    if (data.status === 403) {
      // console.log("权限不足，需要登陆");
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

export async function usePost(url, data, config) {
  const res = await Http.post(url, data, config);
  return res.data;
}

export async function useGet(url, data, config) {
  const res = await Http.get(url, data, config);
  return res.data;
}

const request = async (url, opts = {}) => {
  if (typeof url == "string") {
    opts = { ...opts, url };
  } else {
    opts = url;
  }
  const response = await uni.request(opts);
  return throwOnUniError(response);
};

export { Http, request };
