<template>
  <page-layout>
    <fui-result :type="query.type" :title="query.title || `操作成功`" :descr="query.descr">
      <p style="text-align: center; margin-bottom: 1em">请等待管理员审核</p>
      <p style="text-align: center; margin-bottom: 1em">点击下方“订阅通知”，及时收到微信提醒。</p>
      <fui-button
        @click="onSubsribeChange"
        width="400rpx"
        height="84rpx"
        text="订阅通知"
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
  await utils.gotoPage("Home");
};
async function onSubsribeChange() {
  const priTmplId = "fKHfnkfjq9RqujST4TSLkr-uYzVMi39ZQKOE8AxPW60"; // 社区通知
  const res = await uni.requestSubscribeMessage?.({
    tmplIds: [priTmplId],
  });
  if (res?.[priTmplId] == "accept") {
    uni.showToast({
      title: "操作成功",
      icon: "success",
    });
    await utils.redirect("Home", 1000);
  } else {
    uni.showToast({
      title: "订阅失败",
      icon: "error",
    });
  }
}
</script>
