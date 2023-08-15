<template>
  <page-layout>
    <fui-result :type="query.type" :title="query.title||`操作成功`" :descr="query.descr">
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
