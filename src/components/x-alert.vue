<template>
  <fui-alert
    type="warn"
    spacing
    size="28rpx"
    :marginTop="24"
    :marginBottom="24"
    :title="props.title"
  >
    <slot />
    <slot name="content" />
    <slot name="right" />
  </fui-alert>
</template>

<script setup>
const props = defineProps({
  title: { type: String, default: "" }
});
</script>
