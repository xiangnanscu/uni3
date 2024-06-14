<template>
  <view class="x-title"> <slot /> </view>
</template>

<script setup>
const props = defineProps({
  sizeRate: { type: Number, default: 1 },
  color: { type: String, default: "black" },
});
const fontSize = props.sizeRate * 150 + "%";
const fontColor = props.color;
</script>

<style scoped>
.x-title {
  text-align: center;
  font-size: v-bind(fontSize);
  color: v-bind(fontColor);
  font-weight: bold;
  padding: 20rpx;
  line-height: v-bind(fontSize);
}
</style>
