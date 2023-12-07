<template>
  <page-layout>
    <x-alert title="智慧校园"> </x-alert>
    <div v-if="ready">
      <div v-if="applySuccess">
        <fui-result :type="query.type" title="您已通过申请" :descr="query.descr">
          <p style="text-align: center; margin-bottom: 1em"></p>

          <fui-button
            @click="utils.gotoPage('SchoolHome')"
            width="400rpx"
            height="84rpx"
            text="前往管理"
            type="gray"
            color="#09BE4F"
            bold
          >
          </fui-button>
        </fui-result>
      </div>
      <div v-if="sysadminRole || principalRole">
        <uni-card title="温馨提示">
          <p>两种方式</p>
          <p>
            1.选好学校（不用选班级）点击“邀请班主任”把当前页面分享到班主任群，由班主任自行选择班级申请
          </p>
          <p>2.选好学校和班级后点击“邀请班主任”把当前页面分享给对应班级的班主任</p>
        </uni-card>
        <modelform-fui
          :model="classModel"
          :values="inviteData"
          :sync-values="true"
          :disable-submit="disableSubmit"
          submit-button-open-type="share"
          submitButtonText="邀请班主任"
        ></modelform-fui>
      </div>
      <div v-else>
        <uni-card title="温馨提示">
          <p>此处申请成为班主任</p>
        </uni-card>
        <fui-preview :previewData="previewData"></fui-preview>
        <x-button v-if="classDirectorRole" disabled>已申请</x-button>
        <template v-else-if="query.class_id">
          <x-button @click="regeditClassDirector">申请</x-button>
        </template>
        <template v-else>
          <modelform-fui
            :model="classModel"
            :values="classModel.get_defaults()"
            @send-data="applyClassDirector"
            submitButtonText="申请"
          ></modelform-fui>
        </template>
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
const sysadminRole = ref();
const principalRole = ref();
const classDirectorRole = ref();
const schoolData = ref();
const classData = ref();
const userRole = ref();
const applySuccess = ref();
const inviteData = ref();
const page = utils.getPage();
const disableSubmit = (values) => {
  return !values.school_id;
};
useWxShare({
  title: "智慧校园班主任登记",
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
      label: "班级",
      value: "待选择",
    },
    {
      label: "状态",
      value: "待申请",
    },
  ],
};
const regeditClassDirector = async () => {
  await usePost(`/class_director/get_or_create`, {
    usr_id: user.id,
    school_id: query.school_id,
    class_id: query.class_id,
  });
  uni.showToast({
    title: "已登记,请等待审核",
    duration: 1000,
  });
  utils.gotoPage("SchoolRegeditSuccessPage");
};
const applyClassDirector = async (data) => {
  const applydata = {
    usr_id: user.id,
    school_id: data.school_id,
    class_id: data.class_id,
  };
  console.log("applyClassDirector data", applydata);
  await usePost(`/class_director/get_or_create`, applydata);
  uni.showToast({
    title: "已登记,请等待审核",
    duration: 1000,
  });
  utils.gotoPage("SchoolRegeditSuccessPage");
};

let classModel;
onLoad(async () => {
  helpers.checkRealName();
  const roles = await helpers.getRoles({});
  sysadminRole.value = roles.sys_admin?.status == "通过" ? roles.sys_admin : null;
  principalRole.value = roles.principal?.status == "通过" ? roles.principal : null;
  classDirectorRole.value = roles.class_director;
  if (query.school_id) {
    // 说明是点击管理员分享出来的页面而来
    schoolData.value = await useGet(`/school/detail/${query.school_id}`);
    previewData.list[3].value = schoolData.value.name;
  }
  if (query.class_id) {
    // 说明是点击管理员分享出来的页面而来
    classData.value = await useGet(`/class/detail/${query.class_id}`);
    previewData.list[4].value = classData.value.name;
  }
  const ClassJson = await useGet(`/class_director/json`);
  const setupClassForm = async (classRequired, keepField) => {
    ClassJson.field_names = ["school_id", "class_id"];
    ClassJson.admin.form_names = ["school_id", "class_id"];
    ClassJson.fields.school_id.required = true;
    if (!keepField) {
      ClassJson.fields.school_id = {
        type: "integer",
        label: "学校",
        disabled: true,
        required: true,
        choices: [
          {
            value: schoolData.value.id,
            label: schoolData.value.name,
          },
        ],
        default: schoolData.value.id,
      };
      ClassJson.fields.class_id = {
        type: "integer",
        label: "班级",
        required: !!classRequired,
        choices_url: `/class/choices/school/${schoolData.value.id}`,
      };
    }
    classModel = await Model.create_model_async(ClassJson);
    inviteData.value = classModel.get_defaults();
  };
  if (sysadminRole.value) {
    await setupClassForm(false, true);
  } else if (principalRole.value) {
    //校长角色, 则按其权限显示邀请的表单
    if (!schoolData.value) {
      schoolData.value = await useGet(`/school/detail/${principalRole.value.school_id}`);
    }
    await setupClassForm();
  } else if (classDirectorRole.value) {
    // 班主任角色, 则说明已经申请过了,目前暂时是一个微信号只能绑定一个班主任
    const bindClass = classDirectorRole.value.class_id__name;
    if (query.class_id !== String(classDirectorRole.value.class_id)) {
      // 允许换申请
      uni.showModal({ title: `提醒：已经申请了${bindClass}班主任` });
    }
    const applyStatus = classDirectorRole.value.status;
    previewData.list[4].value = bindClass;
    previewData.list[5].value = applyStatus;
    if (applyStatus == "通过") {
      applySuccess.value = true;
    }
  } else {
    // 点击分享页面而来的普通角色, 根据是否query有class_id来决定是否显示表单
    userRole.value = user;
    if (!query.class_id) {
      setupClassForm(true);
    }
  }

  ready.value = true;
});
</script>
