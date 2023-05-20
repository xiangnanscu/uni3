<template>
  <button @click="emit('selectFiles', { files: [{ name: 1 }] })">点击</button>
</template>

<script setup>
const emit = defineEmits(["selectFiles"]);
</script>
