<template>
  <page-layout>
    <x-alert title="智慧校园"> </x-alert>
    <div v-if="ready">
      <div v-if="query.school_id">
        <uni-card title="温馨提示">
          <p>此处申请成为学校管理员</p>
        </uni-card>
        <fui-preview :previewData="previewData"></fui-preview>
        <x-button v-if="principalRole" disabled>已申请</x-button>
        <x-button v-else @click="regeditPrincipal">申请</x-button>
      </div>
      <div v-else-if="sysadminRole">
        <uni-card title="温馨提示">
          <p>选好学校后点击“邀请学校管理员”把当前页面发送给学校管理员</p>
        </uni-card>
        <modelform-uni
          :model="schoolModel"
          :values="inviteData"
          :sync-values="true"
          :disable-submit="disableSubmit"
          submit-button-open-type="share"
          submitButtonText="邀请学校管理员"
        ></modelform-uni>
      </div>
    </div>
  </page-layout>
</template>
<script setup>
// onShareTimeline
// onShareAppMessage
const user = useUser();
const ready = ref(false);
const query = useQuery();
const principalRole = ref();
const sysadminRole = ref();
const inviteData = ref();
const page = utils.getPage();
const disableSubmit = (values) => {
  return !values.school_id;
};
useWxShare({
  title: "智慧校园学校管理员登记",
  desc: "",
  path: () => {
    const shareUrl = `/${page.route}?${utils.toQueryString(inviteData.value)}`;
    console.log({ shareUrl });
    return shareUrl;
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
    {
      label: "状态",
      value: "待申请",
    },
  ],
};
const regeditPrincipal = async () => {
  await usePost(`/principal/get_or_create`, {
    usr_id: user.id,
    school_id: query.school_id,
  });
  uni.showToast({
    title: "已登记, 请等待审核",
    duration: 1000,
  });
  utils.gotoPage("SchoolRegeditSuccessPage");
};
let schoolModel;
onLoad(async () => {
  if (!user.username) {
    return utils.gotoPage({
      url: "/views/RealNameCert",
      query: { message: "此操作需要先实名认证", redirect: utils.getFullPath() },
      redirect: true,
    });
  }
  if (query.school_id) {
    // 说明是点击管理员分享出来的页面而来
    const school = await useGet(`/school/detail/${query.school_id}`);
    previewData.list[3].value = school.name;
  }
  sysadminRole.value = (await usePost(`/sys_admin/records`, { usr_id: user.id }))[0];
  principalRole.value = (await usePost(`/principal/records`, { usr_id: user.id }))[0];
  if (principalRole.value) {
    previewData.list[4].value = principalRole.value.status;
  }
  const SchoolJson = await useGet(`/principal/json`);
  SchoolJson.field_names = ["school_id"];
  SchoolJson.admin.form_names = ["school_id"];
  schoolModel = await Model.create_model_async(SchoolJson);
  inviteData.value = schoolModel.get_defaults();
  ready.value = true;
});
</script>
