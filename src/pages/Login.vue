<template>
  <page-layout>
    <!-- #ifdef MP-WEIXIN -->
    <LoginWx />
    <!-- #endif -->
    <!-- #ifdef H5 -->
    <LoginH5 />
    <!-- #endif -->
  </page-layout>
</template>

<script setup>
import LoginH5 from "./LoginH5.vue";
import LoginWx from "./LoginWx.vue";
const store = useStore();
store.message = "请先登陆";
</script>
