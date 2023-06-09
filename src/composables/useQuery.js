export function useQuery() {
  const query = ref({});
  onLoad((options) => {
    console.log("useQuery onLoad:", options);
    query.value = options;
  });
  return query;
}
