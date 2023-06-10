export async function useLogin(user) {
  console.log("useLogin called");
  const { login } = useSession();
  const redirectUrl = useRedirect();
  login(user);
  await utils.gotoPage({ url: redirectUrl.value, redirect: true });
}
