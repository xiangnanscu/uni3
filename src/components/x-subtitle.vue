<template>
  <view class="subtitle-container">
    <slot />
  </view>
</template>

<style scoped>
.subtitle-container {
  /* #ifndef APP-NVUE */
  width: 100%;
  display: flex;
  /* #endif */
  justify-content: space-between;
  flex-direction: row;
  color: #666;
  font-size: 80%;
  margin-bottom: 1em;
}
</style>
