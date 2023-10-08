<template>
  <page-layout>
    <x-alert title="红云智慧校园"> </x-alert>
    <uni-card title="温馨提示">
      <p>此处填写家长和子女的信息，子女头像用于刷脸出入校园</p>
    </uni-card>

    <uni-card title="家长" extra="额外信息">
      <modelform-uni
        v-if="loaded"
        :model="ParentModel"
        :values="parent"
        :sync-values="true"
        @success-post="successPost"
        :action-url="actionUrlParent"
        submit-button-text="保存"
      ></modelform-uni>
    </uni-card>

    <uni-card title="子女" extra="额外信息">
      <p style="color: red; font-weight: bold">
        子女头像请务必上传标准清晰头像，随意上传可能导致您的孩子进不了校园
      </p>
    </uni-card>
  </page-layout>
</template>
<script setup>
// onShareTimeline
// onShareAppMessage
useWxShare({
  title: "智慧校园亲子登记",
  desc: "",
});
const { session } = useSession();
const user = session.user;
const loaded = ref(false);
const parent = ref();
const students = ref();
let ParentModel;
onLoad(async () => {
  const modelJson = await useGet(`/parent/json`);
  ParentModel = Model.create_model(modelJson);
  let parentCond = { sfzh: user.username };
  // #ifdef MP-WEIXIN
  parentCond = { openid: user.openid };
  // #endif
  const [parentData] = await usePost(`/parent/records`, parentCond);
  if (parentData) {
    parentData.openid = user.openid;
    parent.value = parentData;
    students.value = await usePost(`/parent_student_relation/records`, {
      parent_id: parent.value.id,
    });
  } else {
    parent.value = { openid: user.openid };
  }
  loaded.value = true;
});
const actionUrlParent = computed(() =>
  parent.value.id ? `/parent/update/${parent.value.id}` : `/parent/create`,
);
const successPost = async (user) => {
  console.log(user);
  uni.showToast({
    title: "已保存",
    icon: "success",
    mask: true,
  });
};
</script>
