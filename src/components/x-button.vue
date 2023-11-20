<template>
  <button
    :style="props.styleString"
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
const useFui = process.env.X_BUTTON_UI === "fui";

const props = defineProps({
  type: { type: String, default: "primary" },
  size: { type: String, default: "mini" }, // default mini
  styleString: {
    type: String,
    default2: "color:#ffffff;backgroundColor:#465CFF;borderColor:#465CFF",
  },
  // https://uniapp.dcloud.net.cn/component/button.html#open-type-%E6%9C%89%E6%95%88%E5%80%BC
  openType: { type: String },
  disabled: { type: Boolean, default: false },
  plain: { type: Boolean, default: true },
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
  backgroundcolor: #465cff;
  bordercolor: #465cff;
}
</style>
