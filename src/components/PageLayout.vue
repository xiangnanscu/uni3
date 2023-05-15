<template>
  <view class="page-layout">
    <div
      v-if="store.message"
      class="global-message"
    >{{ store.message }}</div>
    <div
      v-if="store.error"
      class="global-error"
    >{{ store.error }}</div>
    <fui-spin
      v-if="!store.loading"
      class="fui-spin"
    >
      <view class="fui-loading"></view>
    </fui-spin>
    <slot />
  </view>
</template>
<script>

export default {
  data() {
    return {
      store: useStore()
    };
  },
}
</script>
<style>
.fui-spin {
  position: fixed;

  z-index: 999;
}

.fui-loading {
  width: 50rpx;
  height: 50rpx;
  border-radius: 50%;
  border: 2px solid #465CFF;
  border-left-color: transparent;
}

.global-error {
  padding: 5px;
  color: #b02a37;
  background-color: #f8d7da;
  text-align: center;
}

.global-message {
  padding: 5px;
  color: #0a58ca;
  background-color: #cfe2ff;
  text-align: center;
}

.page-layout {
  padding: 8px 15px;
}
</style>