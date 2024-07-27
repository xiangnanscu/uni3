<template>
  <page-layout>
    <f-alert v-if="status == 'init'">登陆中... </f-alert>
    <div v-else>
      <f-alert type="danger">登陆失败，请重扫:</f-alert>
      <span>
        {{ status }}
      </span>
    </div>
  </page-layout>
</template>

<script setup>
const query = useQuery();
const status = ref("init");
onLoad(async (options) => {
  await helpers.autoLogin();
  try {
    const loginRes = await useGet(`/wx/login_mini?uuid=${query.scene}`);
    if (loginRes == "ok") {
      utils.redirect(`SuccessPage`, { title: "登陆成功" });
    } else {
      status.value = JSON.stringify(loginRes);
    }
  } catch (error) {
    console.log(error);
    status.value = error.message || error.data;
  }
});
</script>
