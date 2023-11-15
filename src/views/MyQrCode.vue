<template>
  <page-layout>
    <div v-if="ready" style="text-align: center; margin-top: 4em">
      <image
        :src="approver.avatar"
        mode="scaleToFill"
        style="width: 50px; height: 50px; border-radius: 25px"
      />
      <div style="margin-bottom: 2em">{{ approver.nickname }}</div>
      <div v-if="!waiting" style="width: 80%; margin: auto">
        <modelform-uni
          :model="applyModel"
          :action-url="`/friends/apply/${approver.id}`"
          label-position="top"
          submit-button-text="发送好友申请"
          @success-post="waiting = true"
        ></modelform-uni>
      </div>
      <div v-else>
        <div style="font-size: 120%; color: green; padding: 5px; margin-bottom: 1em">
          申请已发送
        </div>
        <x-navigator
          open-type="switchTab"
          url="/views/tabbar/Home"
          style="display: flex; justify-content: space-around"
        >
          <x-button size="mini">返回</x-button>
        </x-navigator>
      </div>
    </div>
  </page-layout>
</template>

<script setup>
const loginPage = process.env.UNI_LOGIN_PAGE;
const user = useUser();
const query = useQuery();
const approver = ref();
const ready = ref();
const waiting = ref();
const applyModel = Model.create_model({
  fields: {
    hello_message: { label: "", hint: "附加消息, 选填", maxlength: 50 },
  },
});
onLoad(async (opts) => {
  if (!user.id) {
    await utils.gotoPage({
      url: loginPage,
      query: { redirect: utils.getFullPath() },
      redirect: false,
    });
  } else {
    const uid = query.q.split("/").pop();
    approver.value = await usePost(`/usr/query`, {
      get: { id: uid },
      select: ["id", "nickname", "avatar"],
    });
    ready.value = true;
  }
});
</script>

<style scoped></style>
