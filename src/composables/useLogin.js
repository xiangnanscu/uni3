export function useLogin() {
  const { login } = useSession();
  const redirectUrl = useRedirect();
  return async (user, redirect) => {
    login(user);
    console.log({ cuurentRedirect: redirectUrl.value, passedRedirect: redirect });
    await utils.gotoPage({
      url: redirectUrl.value,
      redirect: true,
    });
  };
}
