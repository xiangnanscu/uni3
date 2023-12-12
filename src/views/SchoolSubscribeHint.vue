<template>
  <page-layout>
    <fui-result
      :type="query.type"
      :title="query.title || '智慧校园'"
      descr="点击订阅及时收到微信提醒"
    >
      <fui-button
        @click="onSubsribeChange"
        width="400rpx"
        height="84rpx"
        text="订阅"
        type="gray"
        color="#09BE4F"
        bold
      ></fui-button>
    </fui-result>

    <div v-if="showHint" style="margin-top: 1em; padding: 1em; color: red">
      订阅失败？请点击右上角三个点-设置-通知管理：点亮“接收通知”，允许“社区通知”
    </div>
  </page-layout>
</template>
<script setup>
// onShareTimeline
// onShareAppMessage
useWxShare({
  title: "智慧校园订阅",
  desc: "校园动态早知道",
});
const showHint = ref();
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
    showHint.value = true;
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
