export const useGet = async (url, config) => {
  const res = await Http.get(url, config);
  return res.data;
};
