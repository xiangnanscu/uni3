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
        redirect: false
      });
    } else if (data.status >= 500) {
      throw new WxResquestError(data);
    }
  }
  return response;
};

class Http {
  static async get(url, opts) {
    const response = await uni.request({
      url,
      method: "get",
      ...opts
    });
    return throwOnUniError(response);
  }

  static async post(url, data, opts) {
    const response = await uni.request({
      url,
      data,
      method: "post",
      ...opts
    });
    return throwOnUniError(response);
  }
}

export { Http };
