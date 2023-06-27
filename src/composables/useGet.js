export const useGet = async (url, data, config) => {
  const res = await Http.get(url, data, config);
  return res.data;
};
