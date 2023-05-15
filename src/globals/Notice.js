class Notice {
  constructor(opts) {
    notification[opts.type](opts);
  }
  static success(message) {
    notification.success({
      message,
    });
  }
  static error(message) {
    notification.error({
      duration: 0,
      message,
    });
  }
  static info(message) {
    notification.info({
      message,
    });
  }
}

export { Notice };
