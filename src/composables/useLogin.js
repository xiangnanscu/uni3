export function useLogin() {
  const { login } = useSession();
  const redirectUrl = useRedirect();
  return async (user) => {
    login(user);
    await utils.gotoPage({
      url: redirectUrl.value,
      redirect: true
    });
  };
}
