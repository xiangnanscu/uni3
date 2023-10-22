export function useRedirect() {
  console.log("useRedirect called");
  const redirect = computed(() => {
    const query = useQuery();
    console.log("useRedirect called query:", JSON.stringify(query.value));
    if (query.value.redirect) {
      const redirectUrl = query.value.redirect;
      console.log("raw redirect Url:", decodeURIComponent(redirectUrl));
      if (redirectUrl.startsWith(process.env.UNI_LOGIN_PAGE)) {
        // 10.22因为未注册用户点击别人分享的需要实名的页面时, 需要先重定向到登录, 再重定向到实名,再重定向到最终页面
        // redirectUrl = process.env.UNI_HOME_PAGE;
      }
      return decodeURIComponent(redirectUrl);
    } else {
      return process.env.UNI_HOME_PAGE;
    }
  });
  return redirect;
}
