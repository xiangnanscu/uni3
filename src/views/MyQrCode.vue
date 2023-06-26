<template>
  <page-layout> OK </page-layout>
</template>

<script setup>
const user = useUser();
const query = ref();
onLoad(async (opts) => {
  console.log("onLoad my_qr_code", opts);
  const uid = decodeURIComponent(opts.q).split("/").pop();
  const res = await usePost(`/friends/apply/${uid}`);
  console.log({ uid, res });
});
</script>

<style scoped></style>
