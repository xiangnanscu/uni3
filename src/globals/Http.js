class WxResquestError extends Error {
  constructor({ type, status, data }) {
    super(data);
    this.type = type;
    this.status = status;
  }
}

const throwOnUniError = (response) => {
  const data = response.data;
  if (typeof data == "object" && data.type == "uni_error") {
    if (data.status === 403) {
      utils.gotoPage({
        url: process.env.UNI_LOGIN_PAGE,
        query: { redirect: utils.getFullPath() },
        redirect: false,
      });
    } else if (data.status >= 500) {
      throw new WxResquestError(data);
    } else if (data.status === 404) {
      throw new WxResquestError(data);
    } else {
      throw new WxResquestError(data);
    }
  }
  return response;
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
