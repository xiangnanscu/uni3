<template>
  <page-layout>
    <div>请稍候...</div>
  </page-layout>
</template>

<script setup>
const { redirect } = useRedirect({ decode: false });
onLoad((query) => {
  // #ifdef MP-WEIXIN
  uni.redirectTo({ url: `/pages/LoginWx?redirect=${redirect.value}` });
  // #endif

  // #ifdef H5
  uni.redirectTo({ url: `/pages/LoginH5?redirect=${redirect.value}` });
  // #endif
});
</script>
