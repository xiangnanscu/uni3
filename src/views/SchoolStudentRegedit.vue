<template>
  <page-layout>
    <x-title>学生信息录入</x-title>
    <div v-if="ready">
      <modelform-uni
        :model="FormModel"
        :values="FormModel.get_defaults()"
        success-url="/views/SchoolStudentRegeditSuccess"
        :success-use-redirect="true"
        :action-url="`/student/register`"
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
const user = useUser();
const ready = ref();
const classDirectorRole = ref();
onLoad(async () => {
  classDirectorRole.value = (
    await usePost(`/class_director/records`, { usr_id: user.id })
  )[0];
  console.log(classDirectorRole);
  const modelJson = await useGet(`/student/json`);
  if (classDirectorRole.value) {
    const className = classDirectorRole.value.class_id__name;
    // const cf = modelJson.fields.class_id;
    // cf.default = className;
    // cf._postValue = classDirectorRole.value.class_id;
    // cf.disabled = true;
    modelJson.fields.class_id = {
      type: "integer",
      label: "班级",
      disabled: true,
      default: classDirectorRole.value.class_id,
      choices: [{ value: classDirectorRole.value.class_id, label: className }],
    };
  }
  FormModel.value = await Model.create_model_async(modelJson);
  ready.value = true;
});
</script>

<style scoped></style>
