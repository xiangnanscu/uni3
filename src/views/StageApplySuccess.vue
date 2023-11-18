<template>
  <page-layout>
    <fui-result :type="query.type" title="成功提交" descr="点击订阅及时收到微信提醒">
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
const priTmplId = "sd-x4lKjBXN5C0NK7vF56ZyGrdL35mUscVam8At8Wtw";
const query = useQuery();
const user = useUser();
async function onSubsribeChange() {
  const res = await uni.requestSubscribeMessage?.({
    tmplIds: [priTmplId],
  });
  if (res?.[priTmplId] == "accept") {
    const subsRes = await usePost(`/subscribe/create`, {
      template_id: priTmplId,
      openid: user.openid,
      status: "启用",
    });
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
const goBack = async (e) => {
  await utils.gotoPage("/views/tabbar/Home");
};
</script>
<style>
page {
  background-color: #fff;
}
</style>
