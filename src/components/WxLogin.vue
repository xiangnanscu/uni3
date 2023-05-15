<script setup>
import { WxLogin } from "@/wxlogin.js";

const redirect_uri = encodeURI("http://jaqn.jahykj.cn/oauth");
onMounted(() => {
  console.log(import.meta.env);
  new WxLogin({
    self_redirect: true,
    id: "login_container",
    appid: import.meta.env.VITE_WX_OPEN_APPID,
    scope: "snsapi_login",
    redirect_uri,
    state: "",
    style: "",
    href: "",
  });
});

// router.push({
//   path: ``,
//   query: {
//     ...route.query,
//   },
// });
</script>
<template>
  <div id="login_container"></div>
</template>

<style></style>
