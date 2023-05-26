<template>
  <uni-grid :column="3" :show-border="false" :square="true" @change="change">
    <uni-grid-item v-for="(url, index) in urls" :index="index" :key="index">
      <view class="grid-item-box">
        <image class="image" :src="url" mode="aspectFill" />
      </view>
    </uni-grid-item>
  </uni-grid>
</template>

<script>
export default {
  name: "XAlbum",
  emits: ["change"],
  props: ["urls"],
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
