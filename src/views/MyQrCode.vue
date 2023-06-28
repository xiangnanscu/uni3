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
      <div v-else>申请已发送</div>
    </div>
  </page-layout>
</template>

<script setup>
const approver = ref();
const ready = ref();
const waiting = ref();
const applyModel = Model.createModel({
  fields: {
    hello_message: { label: "", hint: "附加消息, 选填", maxlength: 50 }
  }
});
onLoad(async (opts) => {
  // console.log("onLoad my_qr_code", opts);
  const uid = decodeURIComponent(opts.q).split("/").pop();
  approver.value = await usePost(`/usr/query`, {
    get: { id: uid },
    select: ["id", "nickname", "avatar"]
  });
  ready.value = true;
});
</script>

<style scoped></style>
