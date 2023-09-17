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
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const excludeTitles = ["社区通知"];
const subscribeItems = ref([]);
const user = useUser();
onLoad((opts) => {
  useGet(`/wx/get_template_list`).then((templates) => {
    subscribeItems.value = templates;
  });
  // const subscribeLogs = await usePost(
  //   `/subscribe/records?select=status&select=id&select=template_id`,
  //   {
  //     openid: user.openid
  //   }
  // );
  // console.log(subscribeLogs);
  // const enabledIds = subscribeLogs
  //   .filter((e) => e.status == "启用")
  //   .map((e) => e.template_id);
  // for (const t of templates) {
  //   t.checked = enabledIds.includes(t.priTmplId) ? true : false;
  // }
  // subscribeItems.value = templates;
});
async function onSubsribeChange(item, selected) {
  const priTmplId = item.priTmplId;
  if (selected) {
    const res = await uni.requestSubscribeMessage?.({
      tmplIds: [priTmplId]
    });
    if (res?.[priTmplId] == "accept") {
      const subsRes = await usePost(`/subscribe/create`, {
        template_id: priTmplId,
        openid: user.openid,
        status: "启用"
      });
      item.checked = true;
      uni.showToast({
        title: "订阅成功",
        icon: "success",
        mask: true
      });
    } else {
      item.checked = false;
      uni.showToast({
        title: "未订阅"
      });
    }
  } else {
    item.checked = false;
    uni.showToast({
      title: "未订阅"
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
