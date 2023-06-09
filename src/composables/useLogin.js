export function useLogin(query) {
  console.log("useLogin called");
  let redirectUrl = query.value.redirect || process.env.UNI_HOME_PAGE;
  if (redirectUrl.startsWith(process.env.UNI_LOGIN_PAGE)) {
    redirectUrl = process.env.UNI_HOME_PAGE;
  }
  const { login } = useSession();
  // 因为utils.gotoPage使用encodeURIComponent来编码
  utils.gotoPage({
    url: decodeURIComponent(redirectUrl),
    redirect: true
  });
}
