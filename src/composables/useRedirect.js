export function useRedirect(query = useQuery()) {
  const redirect = ref();
  onLoad(() => {
    if (query.redirect) {
      redirect.value = decodeURIComponent(query.redirect);
    } else {
      redirect.value = process.env.UNI_HOME_PAGE;
    }
  });
  return redirect;
}
