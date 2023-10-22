export function useRedirect() {
  console.log("useRedirect called");
  const query = useQuery();
  const redirect = computed(() => {
    if (query.redirect) {
      const redirectUrl = query.redirect;
      console.log("raw redirect Url:", decodeURIComponent(redirectUrl));
      if (redirectUrl.startsWith(process.env.UNI_LOGIN_PAGE)) {
        // redirectUrl = process.env.UNI_HOME_PAGE;
      }
      return decodeURIComponent(redirectUrl);
    } else {
      return process.env.UNI_HOME_PAGE;
    }
  });
  return redirect;
}
