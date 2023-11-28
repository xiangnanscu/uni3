<template>
  <page-layout>
    <f-alert v-if="status == 'init'">登陆中... </f-alert>
    <f-alert v-else type="danger">登陆失败,请重扫</f-alert>
  </page-layout>
</template>

<script setup>
const query = useQuery();
const status = ref("init");
onLoad(async (options) => {
  log({ options, query });
  const user = await helpers.autoLogin();
  const loginRes = await useGet(`/wx/login_mini?uuid=${query.scene}`);
  if (loginRes == "ok") {
    utils.redirect(`SuccessPage`, { title: "登陆成功" });
  } else {
    status.value = "error";
  }
});
</script>
