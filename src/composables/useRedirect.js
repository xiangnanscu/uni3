export function useRedirect() {
  const redirect = ref("");
  let redirectUrl = useQuery("redirect") || process.env.UNI_HOME_PAGE;
  if (redirectUrl.startsWith(process.env.UNI_LOGIN_PAGE)) {
    redirectUrl = process.env.UNI_HOME_PAGE;
  }
  // 因为utils.gotoPage使用encodeURIComponent来编码
  redirect.value = decodeURIComponent(redirectUrl);
  const tryRedirect = async () => {
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
