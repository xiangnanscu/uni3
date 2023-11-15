<template>
  <uni-grid
    v-if="urls?.length"
    :column="picColumns"
    :show-border="false"
    :square="true"
    @change="change"
  >
    <uni-grid-item
      v-for="(url, index) in normalizedUrls"
      :index="index"
      :key="index"
      style="margin: auto"
    >
      <view class="grid-item-box">
        <image
          class="grid-item-box"
          :src="url"
          :mode="picMode"
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
  props: ["urls", "columns", "mode"],
  data() {
    return {
      localValue: [],
    };
  },
  computed: {
    normalizedUrls() {
      return this.urls.map((e) => (e.startsWith("http") ? e : "https:" + e));
    },
    picMode() {
      if (this.mode) {
        return this.mode;
      } else {
        return this.urls.length == 1 ? "aspectFit" : "scaleToFill";
      }
    },
    picColumns() {
      if (this.columns) {
        return this.columns;
      } else {
        return this.urls.length < 3 ? this.urls.length : 3;
      }
    },
  },
  methods: {
    previewImages(index) {
      uni.previewImage({
        current: index,
        urls: this.normalizedUrls,
      });
    },
    change(event) {
      this.$emit("change", event);
    },
  },
};
</script>
<style scoped>
.grid-item-box {
  width: 100%;
  height: 100%;
}
</style>
