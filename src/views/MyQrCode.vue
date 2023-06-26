<template>
  <page-layout>
    <div>
      <uni-list :border="false">
        <uni-list-chat
          :avatar-circle="true"
          :title="approver.nickname"
          :avatar="approver.avatar"
          :note="approver.intro"
        ></uni-list-chat>
      </uni-list>
    </div>
  </page-layout>
</template>

<script setup>
const approver = ref();
const ready = ref();
onLoad(async (opts) => {
  console.log("onLoad my_qr_code", opts);
  const uid = decodeURIComponent(opts.q).split("/").pop();
  const res = await usePost(`/friends/apply/${uid}`);
  approver.value = res.approve;
  ready.value = true;
  console.log({ uid, res });
});
</script>

<style scoped></style>
