export function useRedirect({ decode }) {
  console.log("useRedirect called");
  const redirect = ref("");
  onLoad((query) => {
    console.log("useRedirect onLoad:", query);
    let url = query.redirect || process.env.UNI_HOME_PAGE;
    if (url.startsWith(process.env.UNI_LOGIN_PAGE)) {
      url = process.env.UNI_HOME_PAGE;
    }
    if (decode) {
      redirect.value = decodeURIComponent(url);
    } else {
      redirect.value = url;
    }
    console.log("useRedirect onLoad end redirect:", redirect.value);
  });
  const tryRedirect = async () => {
    console.log("tryRedirect called redirect: ", redirect.value);
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
