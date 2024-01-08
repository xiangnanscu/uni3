<template>
  <page-layout>
    <x-alert title="智慧团建"> </x-alert>
    <div v-if="ready">
      <div v-if="query.branch_id">
        <uni-card title="温馨提示">
          <div
            v-if="
              branchAdminRole &&
              query.branch_id &&
              branchAdminRole.branch_id !== query.branch_id
            "
          >
            <template v-if="branchAdminRole.status == '通过'">
              你当前已是{{
                branchAdminRole.branch_id__name
              }}的管理员,不能再申请其他的管理员
            </template>
            <template v-else-if="branchAdminRole.status == '待审核'">
              你当前正在申请{{
                branchAdminRole.branch_id__name
              }}的管理员,不能再申请其他的管理员
            </template>
          </div>
          <p v-else>此处申请成为团组织管理员</p>
        </uni-card>
        <fui-preview :previewData="previewData"></fui-preview>
        <x-button v-if="branchAdminRole && branchAdminRole.status !== '拒绝'" disabled
          >已申请</x-button
        >
        <x-button v-else @click="regeditPrincipal">申请</x-button>
      </div>
      <div v-else-if="sysAdminRole || branchAdminRole">
        <uni-card title="温馨提示">
          <p>选好组织后点击“邀请团组织管理员”即可</p>
        </uni-card>
        <modelform-uni
          :model="branchModel"
          :values="inviteData"
          :sync-values="true"
          @send-data="successPost"
          :disable-submit="disableSubmit"
          submit-button-open-type="share"
          submitButtonText="邀请团组织管理员"
        ></modelform-uni>
      </div>
      <div v-else-if="query.pid">
        <uni-card title="温馨提示">
          <p>此处申请成为团组织管理员</p>
        </uni-card>
        <modelform-uni
          :model="branchModel"
          @send-data="sucessApply"
          submitButtonText="申请"
        ></modelform-uni>
      </div>
    </div>
  </page-layout>
</template>
<script setup>
// onShareTimeline
// onShareAppMessage
const user = useUser();
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
      label: "团组织",
      value: "",
    },
    {
      label: "状态",
      value: "待申请",
    },
  ],
};
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
const sucessApply = async (values) => {
  await usePost(`/branch_admin/get_or_create`, values);
  uni.showToast({
    title: "已登记, 请等待审核",
    duration: 1000,
  });
  utils.gotoPage("BranchRegeditSuccessPage");
};
useWxShare({
  title: "团组织管理员登记",
  desc: "",
  path: () => {
    let shareUrl;
    if (inviteData.value.branch_id)
      //已确定邀请团组织
      shareUrl = `/${page.route}?branch_id=${inviteData.value.branch_id}`;
    else if (branchAdminRole.value?.branch_id)
      //团组织管理员未选择，点击右上角分享
      shareUrl = `/${page.route}?pid=${branchAdminRole.value.branch_id}`;
    else shareUrl = page.$page?.fullPath;
    console.log("shareUrl:", shareUrl);
    return shareUrl;
  },
});

const regeditPrincipal = async () => {
  await usePost(`/branch_admin/get_or_create`, {
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
  helpers.autoLogin(true); // 刷新账号roles信息
  helpers.checkRealName();
  const roles = await helpers.getRoles(); // 不用passedRoles,为了显示已发起的申请
  sysAdminRole.value = roles.sys_admin;
  branchAdminRole.value = roles.branch_admin;
  if (branchAdminRole.value) {
    // 显示已申请的管理员数据
    previewData.list[3].value = branchAdminRole.value.branch_id__name;
    previewData.list[4].value = branchAdminRole.value.status;
  } else if (query.branch_id) {
    // 点击管理员选定机构后分享的页面而来
    const branch = await useGet(`/branch/detail/${query.branch_id}`);
    previewData.list[3].value = branch.name;
  }
  if (sysAdminRole.value || branchAdminRole.value || query.pid) {
    const BranchAdminJson = await useGet(`/branch_admin/json?names=branch_id`);
    const f = BranchAdminJson.fields.branch_id;
    f.choices_url = query.pid
      ? `/branch/apply_choices/${query.pid}`
      : "/branch/invite_choices";
    f.autocomplete = false;
    branchModel = await Model.create_model_async(BranchAdminJson);
    inviteData.value = branchModel.get_defaults();
  }
  ready.value = true;
});
</script>
