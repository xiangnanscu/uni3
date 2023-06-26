<template>
  <page-layout>
    {{ query }}
  </page-layout>
</template>

<script setup>
const user = useUser();
const query = ref();
onLoad(async (query) => {
  console.log("onLoad my_qr_code", query);
  query.value = query;
  const res = await usePost(`/friends/apply/${1}`);
  console.log(res);
});
</script>

<style scoped></style>
