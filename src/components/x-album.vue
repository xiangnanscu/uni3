<template>
  <uni-grid
    :column="columns || 1"
    :show-border="false"
    :square="true"
    @change="change"
  >
    <uni-grid-item v-for="(url, index) in urls" :index="index" :key="index">
      <view class="grid-item-box">
        <image class="image" :src="url" mode="aspectFit" />
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
    change(event) {
      this.$emit("change", event);
    }
  }
};
</script>
<style scoped>
.image,
.grid-item-box {
  width: 100%;
  height: 100%;
}
</style>
