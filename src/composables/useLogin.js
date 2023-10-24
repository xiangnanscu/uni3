export function useLogin(opts) {
  const redirectUrl = opts?.redirectUrl || useRedirect();
  const { login } = useSession();
  return async (user) => {
    login(user);
    console.log("登录用户, 重定向至:", redirectUrl.value);
    await utils.gotoPage({
      url: redirectUrl.value,
      redirect: true,
    });
  };
}
