<template>
  <x-button @click="testHmr">组件热</x-button>
</template>

<script setup>
const testHmr = () => {
  uni.showToast({ title: "41" });
};
</script>
