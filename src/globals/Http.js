class Http {
  static async get(url, opts) {
    return await uni.request({
      url,
      method: "get",
      ...opts
    });
  }

  static async post(url, data, opts) {
    return await uni.request({
      url,
      data,
      method: "post",
      ...opts
    });
  }
}

export { Http };
