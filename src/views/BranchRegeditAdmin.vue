<template>
  <page-layout>
    <x-alert title="智慧团建"> </x-alert>
    <div v-if="ready">
      <div v-if="query.branch_id">
        <uni-card title="温馨提示">
          <p>此处申请成为团委管理员</p>
        </uni-card>
        <fui-preview :previewData="previewData"></fui-preview>
        <x-button v-if="branchAdminRole" disabled>已申请</x-button>
        <x-button v-else @click="regeditPrincipal">申请</x-button>
      </div>
      <div v-else-if="sysAdminRole">
        <uni-card title="温馨提示">
          <p>选好团委后点击“邀请团委管理员”把当前页面发送给团委管理员</p>
        </uni-card>
        <modelform-uni
          :model="branchModel"
          :values="inviteData"
          :sync-values="true"
          @send-data="successPost"
          :disable-submit="disableSubmit"
          submit-button-open-type="share"
          submitButtonText="邀请团委管理员"
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
const branchAdminRole = ref();
const sysAdminRole = ref();
const inviteData = ref({});
const page = utils.getPage();
const disableSubmit = (values) => {
  return !values.branch_id;
};
const successPost = (values) => {
  log(`/${page.route}?branch_id=${inviteData.value.branch_id}`);
  log("successPost", values);
};
useWxShare({
  title: "团委管理员登记",
  desc: "",
  path: () => {
    const shareUrl = `/${page.route}?branch_id=${inviteData.value.branch_id}`;
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
      label: "团委",
      value: "",
    },
    {
      label: "状态",
      value: "待申请",
    },
  ],
};
const regeditPrincipal = async () => {
  await usePost(`/branch_admin/get_or_create`, {
    usr_id: user.id,
    branch_id: query.branch_id,
  });
  uni.showToast({
    title: "已登记, 请等待审核",
    duration: 1000,
  });
  utils.gotoPage("BranchRegeditSuccessPage");
};
let branchModel;
onLoad(async () => {
  helpers.checkRealName();
  const roles = await helpers.getPassedRoles();
  if (query.branch_id) {
    // 说明是点击管理员分享出来的页面而来
    const branch = await useGet(`/branch/detail/${query.branch_id}`);
    previewData.list[3].value = branch.name;
  }
  sysAdminRole.value = roles.sys_admin;
  branchAdminRole.value = roles.branch_admin;
  if (branchAdminRole.value) {
    previewData.list[4].value = branchAdminRole.value.status;
  }
  const BranchJson = await useGet(`/branch_admin/json?names=branch_id`);
  BranchJson.fields.branch_id.choices_url = "/branch/apply_choices";
  branchModel = await Model.create_model_async(BranchJson);
  inviteData.value = branchModel.get_defaults();
  ready.value = true;
});
</script>
