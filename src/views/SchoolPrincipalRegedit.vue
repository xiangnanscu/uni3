<template>
  <page-layout>
    <x-alert title="智慧校园"> </x-alert>
    <div v-if="ready">
      <div v-if="godRole || sysadminRole">
        <uni-card title="温馨提示">
          <p>管理员选好学校后点击“邀请学校管理员”把当前页面发送给学校管理员</p>
        </uni-card>
        <modelform-uni
          :model="schoolModel"
          @send-data="successPost"
          submit-button-open-type="share"
          submitButtonText="邀请学校管理员"
        ></modelform-uni>
      </div>
      <div v-else>
        <uni-card title="温馨提示">
          <p>此处进行学校管理员登记</p>
        </uni-card>
        <fui-preview :previewData="previewData"></fui-preview>
        <x-button @click="regeditPrincipal">登记</x-button>
      </div>
    </div>
  </page-layout>
</template>
<script setup>
// onShareTimeline
// onShareAppMessage
const { session } = useSession();
const ready = ref(false);
const user = session.user;
const query = useQuery();
const godRole = ref(user.permission >= process.env.GOD_PERMISSION ? user : null);
const principalRole = ref();
const sysadminRole = ref();
const schoolId = ref();
const successPost = (data) => {
  schoolId.value = data.school_id;
};
useWxShare({
  title: "智慧校园学校管理员登记",
  desc: "",
  path: (currentPath) => {
    return `${currentPath}?school_id=${schoolId.value}`;
  },
});
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
    {
      label: "学校",
      value: "",
    },
  ],
};
const regeditPrincipal = async () => {
  await usePost(`/principal/get_or_create`, {
    usr_id: user.id,
    school_id: query.school_id,
  });
  uni.showToast({
    title: "已登记",
  });
};
let schoolModel;
onLoad(async () => {
  if (query.school_id) {
    const school = await useGet(`/school/detail/${query.school_id}`);
    previewData.list[3].value = school.name;
  }
  sysadminRole.value = (await usePost(`/sys_admin/records`, { usr_id: user.id }))[0];
  principalRole.value = (await usePost(`/principal/records`, { usr_id: user.id }))[0];
  const SchoolJson = await useGet(`/principal/json`);
  SchoolJson.field_names = ["school_id"];
  SchoolJson.admin.form_names = ["school_id"];
  schoolModel = await Model.create_model_async(SchoolJson);
  ready.value = true;
});
</script>
