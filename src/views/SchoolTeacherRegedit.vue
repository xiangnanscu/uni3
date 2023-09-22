<template>
  <page-layout>
    <x-alert title="红云智慧校园"> </x-alert>
    <uni-card title="温馨提示">
      <p>此处填写教师基本信息</p>
    </uni-card>
    <modelform-uni
      v-if="loaded"
      :model="profileModel"
      :values="postData"
      :sync-values="true"
      label-width="6em"
      @success-post="successPost"
      :action-url="actionUrl"
    ></modelform-uni>
  </page-layout>
</template>
<script setup>
// onShareTimeline
// onShareAppMessage
useWxShare({
  title: "红云智慧校园教师登记",
  imageUrl: "../static/jahy.jpg",
  desc: ""
});
const { session } = useSession();
const user = session.user;
const loginUser = useLogin();
const postData = ref({
  openid: user.openid,
  xm: "",
  sfzh: "",
  avatar: "",
  class: "",
  grade: ""
});
const loaded = ref(false);
const updateId = ref();
let profileModel;
onLoad(async () => {
  const modelJson = await useGet(`/teacher/json`);
  profileModel = Model.createModel(modelJson);
  let teacherQuery = { sfzh: user.username };
  // #ifdef MP-WEIXIN
  teacherQuery = { openid: user.openid };
  // #endif
  const [teacherData] = await usePost(`/teacher/records`, teacherQuery);
  if (teacherData) {
    Object.assign(postData.value, teacherData);
    updateId.value = teacherData.id;
  }
  loaded.value = true;
});
const actionUrl = computed(() =>
  updateId.value ? `/teacher/update/${updateId.value}` : `/teacher/create`
);
const successPost = async (user) => {
  // const newUser = { ...postData.value, ...user };
  // await loginUser(newUser);
  utils.gotoPage({
    name: "SuccessPage",
    query: { title: "提交成功,感谢参与" }
  });
};
</script>
