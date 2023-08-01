<template>
  <view class="content" :class="{ active: active }">
    <image
      class="logo"
      :class="{ active: active }"
      src="../../static/gqt.png"
      mode="aspectFit"
    ></image>
    <view class="tabbar-box-wrap">
      <!-- <view class="tabbar-box">
        <view class="tabbar-box-item" @click="gotoPage('ForumAdd')">
          <image
            class="box-image"
            src="../../static/img/fee8.png"
            mode="aspectFit"
          ></image>
          <text class="explain">团费</text>
        </view>
      </view> -->
      <view class="tabbar-box">
        <view class="tabbar-box-item" @click="gotoPage('ForumAdd')">
          <image
            class="box-image"
            src="../../static/img/create-forum.png"
            mode="aspectFit"
          ></image>
          <text class="explain">创建吧</text>
        </view>
        <view class="tabbar-box-item" @click="gotoPage('VolAdd')">
          <image
            class="box-image"
            src="../../static/img/vol.png"
            mode="aspectFit"
          ></image>
          <text class="explain">发布志愿</text>
        </view>
        <view class="tabbar-box-item" @click="gotoPage('ThreadAdd')">
          <image
            class="box-image"
            src="../../static/img/forum-blue.png"
            mode="aspectFit"
          ></image>
          <text class="explain">发帖</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  data() {
    return {
      active: false
    };
  },
  onLoad() {},
  onShow() {
    // setTimeout(() => {
    this.active = true;
    // }, 500);
  },
  onHide() {
    this.active = false;
  },
  methods: {
    gotoPage(opts) {
      utils.gotoPage(opts);
    }
  }
};
</script>

<style lang="scss" scoped>
.content {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  /* #ifdef H5 */
  height: calc(100vh - var(--window-bottom) - var(--window-top));
  /* #endif */
  /* #ifndef H5 */
  height: 100vh;
  /* #endif */
  transition: opacity 0.3s;
  // background: #999;
  background: #fff;
  opacity: 0;
  &.active {
    opacity: 1;
  }
  .logo {
    position: relative;
    margin-top: -400upx;
    background-color: #fff;
    width: 200upx;
    height: 200upx;
    // z-index: -1;
    opacity: 0;
    transition: opacity 0.3s;
    &.active {
      opacity: 1;
    }
  }
}
.tabbar-box-wrap {
  position: absolute;
  width: 100%;
  padding: 50upx;
  box-sizing: border-box;
  bottom: 0;
  left: 0;
  .tabbar-box {
    position: relative;
    display: flex;
    width: 100%;
    background: #fff;
    border-radius: 20upx;
    padding: 15upx 20upx;
    box-sizing: border-box;
    z-index: 2;
    box-shadow: 0px 2px 5px 2px rgba(0, 0, 0, 0.1);
    &:after {
      content: "";
      position: absolute;
      bottom: -16upx;
      left: 0;
      right: 0;
      margin: auto;
      width: 50upx;
      height: 50upx;
      transform: rotate(45deg);
      background: #fff;
      z-index: 1;
      box-shadow: 2px 2px 5px 1px rgba(0, 0, 0, 0.1);
      border-radius: 2px;
    }
    &:before {
      content: "";
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: #ffffff;
      border-radius: 20upx;
      z-index: 2;
    }
    .tabbar-box-item {
      // position: relative;
      width: 100%;
      z-index: 3;
      margin: 10upx;
      color: $uni-color-subtitle;
      text-align: center;
      font-size: $uni-font-size-base;
      .box-image {
        width: 100%;
        height: $uni-img-size-lg;
      }
    }
  }
}
</style>
