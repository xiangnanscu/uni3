export function useQuery(key) {
  const page = usePage();
  // 使用decodeURI的原因是uni.navigateTo系列API会使用encodeURI编码url
  const queryString = decodeURI(page.fullPath.split("?").slice(1).join("?"));
  const query = queryString
    ? Object.fromEntries(queryString.split("&").map((kv) => kv.split("=")))
    : {};
  return key ? query[key] : query;
}
