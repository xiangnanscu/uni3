<template>
  <page-layout> OK </page-layout>
</template>

<script setup>
const user = useUser();
const query = ref();
onLoad(async (opts) => {
  console.log("onLoad my_qr_code", opts);
  query.value = opts;
  const res = await usePost(`/friends/apply/${1}`);
  console.log(res);
});
</script>

<style scoped></style>
