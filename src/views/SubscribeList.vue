<template>
  <page-layout>
    <x-title>订阅通知</x-title>
    <div v-if="subscribeItems.length">
      <uni-list :border="false" class="uni-list-box">
        <view v-for="(item, index) in subscribeItems" :key="index">
          <div class="uni-list-cell">
            <view style="flex: auto">{{ item.title }}</view>
            <!-- <switch
              :checked="item.checked"
              @change="onSubsribeChange(item, $event.detail.value)"
            /> -->
            <x-button @click="onSubsribeChange(item, true)"> 订阅 </x-button>
          </div>
          <!-- <pre>{{ item.example }} </pre> -->
        </view>
      </uni-list>
    </div>
    <f-alert v-else> 没有记录</f-alert>
  </page-layout>
</template>

<script setup>
// onShareAppMessage
const excludeTitles = [];
const subscribeItems = ref([]);
const user = useUser();
onLoad(async (opts) => {
  const templates = await useGet(`/wx/get_template_list`);
  const subscribeLogs = await usePost(`/subscribe/records?select=status&select=id&select=template_id`, {
    openid: user.openid,
  });
  const enabledIds = subscribeLogs.filter((e) => e.status == "启用").map((e) => e.template_id);
  for (const t of templates) {
    t.checked = enabledIds.includes(t.priTmplId) ? true : false;
  }
  subscribeItems.value = templates.filter((e) => !excludeTitles.includes(e.title));
  // #ifdef MP-WEIXIN
  wx.getSetting({
    withSubscriptions: true,
    success(res) {
      console.log(res.authSetting);
      // res.authSetting = {
      //   "scope.userInfo": true,
      //   "scope.userLocation": true
      // }
      console.log(res.subscriptionsSetting);
      // res.subscriptionsSetting = {
      //   mainSwitch: true, // 订阅消息总开关
      //   itemSettings: {   // 每一项开关
      //     SYS_MSG_TYPE_INTERACTIVE: 'accept', // 小游戏系统订阅消息
      //     SYS_MSG_TYPE_RANK: 'accept'
      //     zun-LzcQyW-edafCVvzPkK4de2Rllr1fFpw2A_x0oXE: 'reject', // 普通一次性订阅消息
      //     ke_OZC_66gZxALLcsuI7ilCJSP2OJ2vWo2ooUPpkWrw: 'ban',
      //   }
      // }
    },
  });
  // #endif
});
async function onSubsribeChange(item, selected) {
  const priTmplId = item.priTmplId;
  if (selected) {
    const res = await uni.requestSubscribeMessage?.({
      tmplIds: [priTmplId],
    });
    if (res?.[priTmplId] == "accept") {
      const subsRes = await usePost(`/subscribe/create`, {
        template_id: priTmplId,
        openid: user.openid,
        status: "启用",
      });
      item.checked = true;
      uni.showToast({
        title: "订阅成功",
        icon: "success",
      });
    } else {
      item.checked = false;
      uni.showToast({
        title: "订阅失败",
        icon: "error",
      });
    }
  } else {
    item.checked = false;
    uni.showToast({
      title: "订阅失败",
      icon: "error",
    });
  }
}
</script>

<style scoped>
.uni-list-box {
  padding: 2em;
}
.uni-list-cell {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
  padding: 0 2em;
  margin-bottom: 2em;
}
</style>
