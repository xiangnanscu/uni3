<template>
  <!-- <fui-alert
    type="warn"
    spacing
    size="28rpx"
    :marginTop="24"
    :marginBottom="24"
    :iconColor="props.mainColor"
    :style="alertStyle"
    background="#fff"
    :color="props.mainColor"
    :title="props.title"
  >
    <slot />
    <slot name="content" />
    <slot name="right" />
  </fui-alert> -->
  <uni-notice-bar
    class="notice-bar"
    :text="props.title"
    :icon-type="props.iconType"
    show-icon
  />
</template>

<script setup>
const props = defineProps({
  iconType: { type: String, default: "info" },
  mainColor: { type: String, default: "#ffb703" },
  title: { type: String, default: "" }
});
const alertStyle = computed(() => ({ border: `1px solid ${props.mainColor}` }));
</script>
<style scoped>
/* .fui-alert__waiting {
  background-color: var(--fui-color-primary, #465cff) !important;
}

.fui-alert__success {
  background-color: var(--fui-color-success, #09be4f) !important;
}

.fui-alert__warn {
  background-color: var(--fui-color-warning, #ffb703) !important;
}

.fui-alert__clear {
  background-color: var(--fui-color-danger, #ff2b2b) !important;
} */
</style>
