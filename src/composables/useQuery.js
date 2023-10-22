export function useQuery() {
  const query = reactive({});
  onLoad((options) => {
    for (const [name, value] of Object.entries(options)) {
      query[name] = decodeURIComponent(value);
    }
  });
  return query;
}
