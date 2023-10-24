<template>
  <page-layout>
    <x-alert title="智慧校园"> </x-alert>
    <div v-if="ready">
      <div v-if="godRole || sysadminRole || principalRole">
        <uni-card title="温馨提示">
          <p>选好学校和班级后点击“邀请班主任”把当前页面发送给班主任</p>
        </uni-card>
        <modelform-uni
          :model="classModel"
          :values="classModel.get_defaults()"
          @send-data="successPost"
          submit-button-open-type="share"
          submitButtonText="邀请学校管理员"
        ></modelform-uni>
      </div>
      <div v-else>
        <uni-card title="温馨提示">
          <p>此处申请成为学校管理员</p>
        </uni-card>
        <fui-preview :previewData="previewData"></fui-preview>
        <x-button v-if="principalRole" disabled>已申请</x-button>
        <x-button v-else @click="regeditClassDirector">申请</x-button>
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
const godRole = ref(user.permission >= process.env.GOD_PERMISSION ? user : null);
const classDirectorRole = ref();
const principalRole = ref();
const sysadminRole = ref();
const schoolId = ref();
const classId = ref();
const successPost = (data) => {
  schoolId.value = data.school_id;
  classId.value = data.class_id;
  console.log(utils.getPage());
  console.log(`${utils.getPage().$page.path}?${utils.toQueryString(data)}`);
};
useWxShare({
  title: "智慧校园学校管理员登记",
  desc: "",
  path: (page) => {
    return `${page.path}?${utils.toQueryString({
      school_id: schoolId.value,
      class_id: classId.value,
    })}`;
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
      value: "",
    },
    {
      label: "状态",
      value: "",
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
  utils.gotoPage("Home");
};
let classModel;
onLoad(async () => {
  if (!user.username) {
    return utils.gotoPage({
      url: "/views/RealNameCert",
      query: { message: "此操作需要先实名认证", redirect: utils.getFullPath() },
      redirect: true,
    });
  }
  if (query.school_id && query.class_id) {
    // 说明是点击管理员分享出来的页面而来
    const school = await useGet(`/school/detail/${query.school_id}`);
    previewData.list[3].value = school.name;
    const _class = await useGet(`/class/detail/${query.class_id}`);
    previewData.list[4].value = _class.name;
  }
  sysadminRole.value = (await usePost(`/sys_admin/records`, { usr_id: user.id }))[0];
  principalRole.value = (await usePost(`/principal/records`, { usr_id: user.id }))[0];
  classDirectorRole.value = (
    await usePost(`/class_director/records`, { usr_id: user.id })
  )[0];
  if (classDirectorRole.value) {
    previewData.list[5].value = classDirectorRole.value.status;
  }
  const ClassJson = await useGet(`/class_director/json`);
  ClassJson.field_names = ["school_id", "class_id"];
  ClassJson.admin.form_names = ["school_id", "class_id"];
  if (principalRole.value) {
    const schoolField = ClassJson.fields.class_id;
    schoolField.type = "integer";
    schoolField.autocomplete = false;
    schoolField.choices_url = `/class/choices/school/${principalRole.value.school_id}`;
    // schoolField.attrs = { fui: true };
    // schoolField.disabled = true;
    // schoolField.default = principalRole.value.school_id__name;
    // schoolField.type = "string";
    ClassJson.fields.school_id = {
      type: "integer",
      label: "学校",
      disabled: true,
      choices: [
        {
          value: principalRole.value.school_id,
          label: principalRole.value.school_id__name,
        },
      ],
      default: principalRole.value.school_id,
    };
  } else if (classDirectorRole.value) {
  }
  classModel = await Model.create_model_async(ClassJson);
  ready.value = true;
});
</script>
