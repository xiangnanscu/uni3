<template>
  <fui-alert
    type="warn"
    spacing
    size="28rpx"
    :marginTop="24"
    :marginBottom="24"
    v-bind="$attrs"
  >
    <slot />
    <slot name="content" />
    <slot name="right" />
  </fui-alert>
</template>

<script setup></script>
