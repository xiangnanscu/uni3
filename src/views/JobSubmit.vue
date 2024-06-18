<template>
  <page-layout>
    <x-title>{{ query.job_name }}</x-title>
    <x-title :size-rate="0.6">
      {{ hintMessage }}
    </x-title>
    <modelform-fui
      v-if="ready"
      :disabled="disableForm"
      label-position="left"
      label-align="left"
      :model="ResumeSubmissionModel"
      :values="values"
      :sync-values="true"
      success-url="SuccessPage"
      action-url="/resume_submission/create"
      :hide-submit-button="disableForm"
    ></modelform-fui>
  </page-layout>
</template>

<script setup>
// onShareTimeline
// onShareAppMessage
const testData = {
  avatar:
    "https://lzwlkj.oss-cn-shenzhen.aliyuncs.com/jaqn/img/05c6ed64-d23b-43f1-8991-0bcb9d3b4b77.jpg",
  edu_exp: [
    {
      content: "本科就读",
      end_date: "",
      major: "社会学",
      school_name: "北京大学",
      start_date: "2024-06",
    },
  ],
  highest_education: "本科",
  intro: "乐观向上",
  job_type: "全职",
  life_photo: "",
  marriage_status: "未婚",
  name: "张三",
  phone: "13888888888",
  sex: "男",
  wechat_id: "ddddds",
  work_exp: [
    {
      company_name: "网易",
      content: "游戏运维",
      end_date: "2024-07",
      job_position: "运维",
      start_date: "2024-06",
    },
  ],
  work_years: "3年-5年",
};
const user = helpers.checkLogin();
const query = useQuery();
const values = ref({});
const ResumeSubmissionModel = ref();
const ready = ref(false);
const hintMessage = computed(() => {
  if (!query.status) {
    return ``;
  } else if (query.status == "待审核") {
    return `已投简历,请耐心等待审核`;
  } else if (query.status == "拒绝") {
    return `简历被拒绝`;
  } else if (query.status == "通过") {
    return `简历已通过审核`;
  } else {
    return ``;
  }
});
const disableForm = computed(() => query.status === "通过" || query.status === "待审核");
onLoad(async () => {
  ResumeSubmissionModel.value = await Model.create_model_async(`/resume_submission/form_json`);
  let currentResume;
  if (!query.status) {
    currentResume = await usePost(`/resume/get_or_create`, [
      { usr_id: user.id },
      {},
      ResumeSubmissionModel.value.names.filter((name) => name !== "status"),
    ]);
  } else {
    currentResume = await usePost(`/resume_submission/get`, {
      job_id: query.job_id,
      usr_id: user.id,
    });
  }
  Object.assign(values.value, { job_id: query.job_id, usr_id: user.id }, currentResume);
  ready.value = true;
});
</script>
