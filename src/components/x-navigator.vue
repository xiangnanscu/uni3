<template>
  <div @click="gotoPage">
    <slot />
  </div>
</template>

<script setup>
const props = defineProps({
  redirect: { type: Boolean },
  openType: { type: String, default: "navigate" },
  url: { type: String },
});
const gotoPage = async () => {
  await utils.gotoPage({
    url: props.url,
    redirect: props.redirect,
  });
};
</script>
<style scoped></style>
