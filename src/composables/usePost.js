export async function usePost(url, data, config) {
  const res = await Http.post(url, data || {}, config);
  res.data = ref(res.data);
  return res;
}
