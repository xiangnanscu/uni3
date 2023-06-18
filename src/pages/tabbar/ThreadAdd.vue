<template>
  <view class="content"> </view>
</template>

<script>
export default {
  data() {
    return {};
  },
  onLoad() {},
  onShow() {
    uni.navigateTo({ url: "/pages/ThreadAdd" });
  },
  onHide() {
    this.active = false;
  },
  methods: {
    goToPage(url) {
      if (!url) return;
      uni.navigateTo({
        url
      });
    }
  }
};
</script>
