<template>
  <a-spin v-if="loading" :indicator="indicator" />
</template>
<script lang="ts" setup>
import { storeToRefs } from "pinia";
import { LoadingOutlined } from "@ant-design/icons-vue";
import { h } from "vue";

const { loading } = storeToRefs(useMyStore());
const indicator = h(LoadingOutlined, {
  style: {
    fontSize: "3em",
    fontWeight: "bold",
  },
  spin: true,
});
</script>

<style scoped>
.ant-spin {
  position: absolute;
  top: 25%;
  left: 50%;
  z-index: 10;
}
</style>
