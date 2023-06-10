export function useQuery() {
  const query = ref({});
  onLoad((options) => {
    console.log("useQuery onLoad:", options);
    for (const [name, value] of Object.entries(options)) {
      options[name] = decodeURIComponent(value);
    }
    query.value = options;
  });
  return query;
}
