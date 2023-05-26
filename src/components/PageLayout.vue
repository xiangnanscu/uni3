<template>
  <div>
    <view class="page-layout">
      <div v-if="message" class="global-message">{{ message }}</div>
      <div v-if="error" class="global-error">{{ error }}</div>
      <slot />
    </view>
  </div>
</template>
<script setup>
const { message, error } = storeToRefs(useStore());
</script>
<style>
.page-layout {
  padding: 0 8px;
}

.fui-spin {
  position: fixed;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 90vh;
  min-width: 100vw;
  z-index: 999;
}

.fui-loading {
  width: 50rpx;
  height: 50rpx;
  border-radius: 50%;
  border: 2px solid #465cff;
  border-left-color: transparent;
}

.global-error {
  padding: 5px;
  color: #b02a37;
  background-color: #f8d7da;
  text-align: center;
  border-radius: 16rpx;
}

.global-message {
  padding: 5px;
  color: #0a58ca;
  background-color: #cfe2ff;
  text-align: center;
  border-radius: 16rpx;
}
</style>
