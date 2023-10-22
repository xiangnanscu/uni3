export function useQuery() {
  const query = ref({});
  onLoad((options) => {
    for (const [name, value] of Object.entries(options)) {
      query.value[name] = decodeURIComponent(value);
    }
  });
  return query;
}
