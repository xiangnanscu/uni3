<template>
  <page-layout>
    <x-title>学生信息录入</x-title>
    <div v-if="ready">
      <modelform-uni
        :model="FormModel"
        :sync-values="false"
        success-url="/views/SchoolStudentRegeditSuccess"
        :success-use-redirect="true"
        :action-url="actionUrl"
      ></modelform-uni>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
// onShareTimeline
// onShareAppMessage
useWxShare({
  title: "智慧校园学生录入",
  desc: "",
});
const FormModel = ref();
const query = useQuery();
const ready = ref();
const actionUrl = computed(() => `/student/register`);
onLoad(async () => {
  const modelJson = await useGet(`/student/json`);
  FormModel.value = Model.create_model(modelJson);
  ready.value = true;
});
</script>

<style scoped></style>
