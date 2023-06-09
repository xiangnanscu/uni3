export function useRedirect(query) {
  console.log("useRedirect called");
  const redirect = ref("");
  const tryRedirect = async () => {
    let redirectUrl = query.value.redirect || process.env.UNI_HOME_PAGE;
    if (redirectUrl.startsWith(process.env.UNI_LOGIN_PAGE)) {
      redirectUrl = process.env.UNI_HOME_PAGE;
    }
    // 因为utils.gotoPage使用encodeURIComponent来编码
    redirect.value = decodeURIComponent(redirectUrl);
    await utils.gotoPage({
      url: redirect.value,
      redirect: true
    });
  };
  return {
    redirect,
    tryRedirect
  };
}
