<template>
  <view class="fui-chatbar__fixed">
    <view class="fui-chatbar__wrap">
      <view class="fui-chatbar__icon-box" @tap="change">
        <fui-icon :name="isVoice ? 'voice' : 'keyboard'"></fui-icon>
      </view>
      <view class="fui-chatbar__input-box">
        <textarea
          :value="modelValue"
          @input="onTextInput"
          :enableNative="false"
          auto-height
          :show-count="false"
          fixed
          disable-default-padding
          :cursor-spacing="spacing"
          confirm-type="send"
          class="fui-chatbar__input"
          @focus="focusChange"
          @blur="blurChange"
        ></textarea>
        <view class="fui-chatbar__voice" v-if="!isVoice">
          <text class="fui-chatbar__voice-text">按住 说话</text>
        </view>
      </view>
      <view class="fui-chatbar__icon-box fui-chatbar__send-box">
        <text class="fui-chatbar__send" @click="emit('sendMessage', modelValue)"
          >发送</text
        >
      </view>
    </view>
    <!-- #ifdef APP-NVUE -->
    <fui-safe-area background="#f8f8f8"></fui-safe-area>
    <!-- #endif -->
    <!-- #ifndef APP-NVUE -->
    <fui-safe-area background="#f8f8f8" v-if="!focus"></fui-safe-area>
    <!-- #endif -->
  </view>
</template>

<script setup>
const props = defineProps({
  modelValue: { type: String, default: "" }
});
const emit = defineEmits(["update:modelValue", "sendMessage"]);
const onTextInput = ($event) => {
  emit("update:modelValue", $event.detail.value);
};
</script>

<script>
export default {
  data() {
    const spacing = 12;
    return {
      spacing,
      //keyboard
      isVoice: true,
      focus: false
    };
  },
  methods: {
    change() {
      this.isVoice = !this.isVoice;
    },
    focusChange() {
      this.focus = true;
    },
    blurChange() {
      this.focus = false;
    }
  }
};
</script>

<style>
/* #ifndef APP-NVUE */
page {
  font-weight: normal;
}

/* #endif */

.fui-align__center {
  flex-direction: row;
}

.fui-section__title {
  margin-left: 32rpx;
  /* #ifdef APP-NVUE */
  margin-top: 64rpx;
  /* #endif */
}

/* 布局内容样式 start */
.fui-chatbar__wrap {
  /* #ifndef APP-NVUE */
  width: 100%;
  display: flex;
  /* #endif */
  padding: 6px 0;
  flex-direction: row;
  align-items: flex-end;
  justify-content: space-between;
  background: #f8f8f8;
}

.fui-chatbar__input-box {
  /* #ifndef APP-NVUE */
  width: 100%;
  display: flex;
  /* #endif */
  flex-direction: row;
  flex: 1;
  position: relative;
}

.fui-chatbar__input {
  /* #ifndef APP-NVUE || MP-ALIPAY || MP-QQ */
  width: 100%;
  min-height: 32rpx;
  box-sizing: content-box;
  padding: 20rpx;
  /* #endif */
  /* #ifdef MP-ALIPAY || MP-QQ */
  line-height: 1;
  min-height: 72rpx;
  /* #endif */
  flex: 1;
  /* #ifdef APP-NVUE */
  height: 72rpx;
  padding: 16rpx 20rpx;
  /* #endif */
  border-radius: 8rpx;
  font-size: 32rpx;
  background: #fff;
}

.fui-chatbar__voice {
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  background: #fff;
  border-radius: 8rpx;
  text-align: center;
  /* #ifndef APP-NVUE */
  display: flex;
  z-index: 10;
  /* #endif */
  align-items: center;
  justify-content: center;
  /* #ifdef H5 */
  cursor: pointer;
  /* #endif */
}

.fui-chatbar__voice:active {
  background-color: #ddd;
}

.fui-chatbar__voice-text {
  text-align: center;
  font-weight: bold;
  font-size: 32rpx;
}

.fui-chatbar__icon-box {
  height: 72rpx;
  padding: 0 16rpx;
  /* #ifndef APP-NVUE */
  display: flex;
  flex-shrink: 0;
  /* #endif */
  align-items: center;
  justify-content: center;
  /* #ifdef H5 */
  cursor: pointer;
  /* #endif */
}

.fui-chatbar__icon-box:active {
  opacity: 0.5;
}

.fui-chatbar__pdl {
  padding-left: 0;
}

.fui-chatbar__send-box {
  padding: 0 30rpx;
}

.fui-chatbar__send {
  color: #465cff;
  font-size: 30rpx;
}

.fui-chatbar__fixed {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  /* #ifndef APP-NVUE */
  z-index: 10;
  /* #endif */
}

/* 布局内容样式 end */
</style>
