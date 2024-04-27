<template>
  <button
    :style="
      `color:#ffffff;background-color:#465CFF;border-color:#465CFF;margin-top:1em` +
      props.styleString
    "
    :type="props.type"
    :plain="props.plain"
    :size="props.size"
    :disabled="props.disabled"
    :open-type="props.openType"
    @click="emit('click', $event)"
    @chooseavatar="emit('chooseavatar', $event)"
    @getphonenumber="emit('getphonenumber', $event)"
  >
    <slot />
  </button>
</template>
<script setup>
//
const emit = defineEmits(["click", "getphonenumber", "chooseavatar"]);

const props = defineProps({
  type: { type: String, default: "primary" },
  size: { type: String, default: "default" }, // default mini
  styleString: { type: String, default: "" },
  // https://uniapp.dcloud.net.cn/component/button.html#open-type-%E6%9C%89%E6%95%88%E5%80%BC
  openType: { type: String },
  disabled: { type: Boolean, default: false },
  plain: { type: Boolean, default: false },
});
</script>
<script>
export default {
  options: { styleIsolation: "shared" },
};
</script>
<style scoped>
.x {
  color: #ffffff;
  background-color: #465cff;
  border-color: #465cff;
}
</style>
