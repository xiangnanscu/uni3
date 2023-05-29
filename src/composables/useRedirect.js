export function useRedirect({ decode }) {
  const redirect = ref("");
  onLoad((query) => {
    redirect.value = query.redirect
      ? decode
        ? decodeURIComponent(query.redirect)
        : query.redirect
      : "/pages/tabbar/Home";
  });
  return {
    redirect
  };
}
