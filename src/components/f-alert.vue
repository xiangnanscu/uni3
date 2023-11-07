<template>
  <div class="hint-text">
    <slot />
  </div>
</template>

<script setup>
const props = defineProps({
  type: { type: String, default: "plain" },
});
const TypeColorMap = {
  plain: { color: "#465CFF", background: "transparent" },
  warning: { color: "#fff", background: "#FFB703" },
  primary: { color: "#fff", background: "#465CFF" },
  danger: { color: "#fff", background: "#FF2B2B" },
  success: { color: "#fff", background: "#09BE4F" },
};
const color = TypeColorMap[props.type].color;
const background = TypeColorMap[props.type].background;
</script>
<style scoped>
.hint-text {
  color: v-bind(color);
  background-color: v-bind(background);
  text-align: center;
  font-size: 90%;
  padding: 8px;
  border-radius: 16rpx;
}
</style>
