<template>
  <button @click="testHmr">组件热</button>
</template>

<script setup>
const testHmr = () => {
  uni.showToast({ title: "安1" });
};
</script>
