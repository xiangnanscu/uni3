export function useRedirect({ decode }) {
  const redirect = ref("");
  onLoad((query) => {
    const url = query.redirect || "/pages/tabbar/Home";
    if (decode) {
      return decodeURIComponent(url);
    } else {
      return url;
    }
  });
  return {
    redirect
  };
}
