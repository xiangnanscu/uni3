<template>
  <page-layout>
    <x-alert title="智慧校园"> </x-alert>
    <uni-card title="温馨提示">
      <p>此处进行班主任登记</p>
    </uni-card>
    <fui-preview :previewData="previewData"></fui-preview>
    <modelform-uni
      v-if="loaded"
      :model="profileModel"
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
  title: "智慧校园教师登记",
  desc: "",
});
const { session } = useSession();
const user = session.user;
const query = useQuery();
const previewData = {
  list: [
    {
      label: "姓名",
      value: user.xm,
    },
    {
      label: "身份证号",
      value: user.username,
    },
    {
      label: "手机号",
      value: user.phone,
    },
  ],
};
const postData = ref({
  openid: user.openid,
  xm: "",
  sfzh: "",
  avatar: "",
  class: "",
  grade: "",
});
const loaded = ref(false);
const updateId = ref();
let profileModel;
onLoad(async () => {
  const [teacherData] = await usePost(`/teacher/records`, { usr_id: user.id });
  const SchoolJson = await useGet(`/teacher/json`);
  SchoolJson.field_names = ["school_id"];
  SchoolJson.admin.form_names = ["school_id"];
  profileModel = await Model.create_model_async(SchoolJson);
  console.log({ profileModel });
  if (teacherData) {
    Object.assign(postData.value, teacherData);
    updateId.value = teacherData.id;
  }
  loaded.value = true;
});
const actionUrl = computed(() =>
  updateId.value ? `/teacher/update/${updateId.value}` : `/teacher/create`,
);
const successPost = async (user) => {
  // const newUser = { ...postData.value, ...user };
  // await loginUser(newUser);
  utils.gotoPage({
    name: "SuccessPage",
    query: { title: "提交成功,感谢参与" },
  });
};
</script>
