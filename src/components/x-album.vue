<template>
  <uni-grid
    :column="columns || 1"
    :show-border="false"
    :square="true"
    @change="change"
  >
    <uni-grid-item v-for="(url, index) in urls" :index="index" :key="index">
      <view class="grid-item-box">
        <image
          class="grid-item-box"
          :src="url"
          mode="aspectFit"
          @click="previewImages(index)"
        />
      </view>
    </uni-grid-item>
  </uni-grid>
</template>

<script>
export default {
  name: "XAlbum",
  emits: ["change"],
  props: ["urls", "columns"],
  data() {
    return {
      localValue: []
    };
  },
  methods: {
    previewImages(index) {
      uni.previewImage({
        current: index,
        urls: this.urls,
        loop: true
      });
    },
    change(event) {
      this.$emit("change", event);
    }
  }
};
</script>
<style scoped>
.grid-item-box {
  width: 100%;
  height: 100%;
}
</style>
