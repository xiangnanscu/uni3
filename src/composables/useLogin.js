export function useLogin({ redirectUrl }) {
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
