<template>
  <page-layout>
    <fui-result title="敬请期待" descr="此功能正在开发中">
      <fui-button
        @click="goBack"
        width="400rpx"
        height="84rpx"
        text="返回首页"
        type="gray"
        color="#09BE4F"
        bold
      ></fui-button>
    </fui-result>
  </page-layout>
</template>
<script setup>
// const props = defineProps({
//   type: { type: String, default: "success" },
//   title: { type: String, default: "操作成功" },
//   descr: { type: String, default: "" }
// });
const query = useQuery();

const goBack = async (e) => {
  await utils.gotoPage("/views/tabbar/Home");
};
</script>
