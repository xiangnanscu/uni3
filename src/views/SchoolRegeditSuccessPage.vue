<template>
  <page-layout>
    <fui-result
      :type="query.type"
      :title="query.title || `操作成功`"
      :descr="query.descr"
    >
      <p style="text-align: center; margin-bottom: 1em">
        订阅“社区通知”，孩子出入校园第一时间知晓
      </p>
      <fui-button
        @click="goBack"
        width="400rpx"
        height="84rpx"
        text="前往订阅消息"
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
  await utils.gotoPage("/views/SubscribeList");
};
</script>
