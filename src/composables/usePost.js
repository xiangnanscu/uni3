export async function usePost(url, data, config) {
  const res = await Http.post(url, data, config);
  return res.data;
}
