<template>
  <div>跳转中...</div>
</template>

<script setup>
const loginPage = process.env.UNI_LOGIN_PAGE;
const user = useUser();
const query = useQuery();
onLoad(async (opts) => {
  await utils.redirect(`/views/${query.q.split("/q/").pop()}`);
});
</script>

<style scoped></style>
