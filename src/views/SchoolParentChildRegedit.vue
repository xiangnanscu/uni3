<template>
  <page-layout>
    <x-alert title="红云智慧校园"> </x-alert>
    <uni-card title="温馨提示">
      <p>此处填写家长和子女的信息，子女头像用于刷脸出入校园</p>
      <p style="color: red; font-weight: bold">
        子女头像请务必上传标准清晰头像，随意上传可能导致您的孩子进不了校园
      </p>
    </uni-card>
    <modelform-uni
      v-if="loaded"
      :model="regeditModel"
      :values="postData"
      :sync-values="true"
      @success-post="successPost"
      :action-url="actionUrl"
    ></modelform-uni>
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
const loginUser = useLogin();
const postData = ref({
  openid: user.openid,
  xm: "",
  sfzh: "",
  // avatar: ""
  // class: "",
  // grade: ""
});
const loaded = ref(false);
const updateId = ref();
let regeditModel;
onLoad(async () => {
  const modelJson = await useGet(`/parent_student_relation/json`);
  modelJson.fields.children.model.admin = {
    form_names: ["xm", "sfzh", "avatar", "grade", "class"],
  };
  regeditModel = Model.create_model(modelJson);
  let regeditQuery = { sfzh: user.username };
  // #ifdef MP-WEIXIN
  regeditQuery = { openid: user.openid };
  // #endif
  const [regeditData] = await usePost(
    `/parent_student_relation/regedit_records`,
    regeditQuery,
  );
  if (regeditData) {
    Object.assign(postData.value, regeditData);
    updateId.value = regeditData.id;
  }
  loaded.value = true;
});
const actionUrl = computed(() =>
  updateId.value
    ? `/parent_student_relation/regedit_update/${updateId.value}`
    : `/parent_student_relation/regedit_create`,
);
const successPost = async (user) => {
  utils.gotoPage({
    redirect: true, // 为了防止在成功页面点击返回到亲子登记form再提交的行为(此时仍然按create提交,但实际上应为update)
    name: updateId.value ? "SuccessPage" : "SchoolSuccessPage",
    query: { title: updateId.value ? "修改成功" : "登记成功" },
  });
};
</script>
