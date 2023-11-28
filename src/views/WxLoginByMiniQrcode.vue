<script setup>
const { login } = useSession();
const route = useRoute();
const router = useRouter();
const { disableLoading } = storeToRefs(useMyStore());
disableLoading.value = true;
const imgSrc = ref("");
const uuid = utils.uuid().slice(0, 32);
const blob = await useGet(`/wx/get_login_acode?uuid=${uuid}`, {
  responseType: "blob",
});
imgSrc.value = URL.createObjectURL(blob);
const timer = ref(0);
timer.value = setInterval(async () => {
  const res = await useGet(`/wx/get_login_mini_state?uuid=${uuid}`);
  if (res.user) {
    const redirect = route.query.redirect;
    const path = redirect ? decodeURIComponent(redirect) : "/";
    login(res.user);
    return router.push(path);
  }
}, 1000);
onBeforeUnmount(() => {
  log("onBeforeUnmount");
  clearInterval(timer.value);
  disableLoading.value = false;
});
</script>

<template>
  <div style="width: 400px; margin: auto">
    <h1 class="center">使用微信扫码登录</h1>
    <img v-if="imgSrc" :src="imgSrc" />
  </div>
</template>
