export function useRedirect() {
  const redirect = ref("");
  onLoad((query) => {
    redirect.value = query.redirect
      ? decodeURIComponent(query.redirect)
      : "/pages/tabbar/Home";
  });
  return {
    redirect
  };
}
