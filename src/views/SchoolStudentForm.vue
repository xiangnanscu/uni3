<template>
  <page-layout>
    <x-title>学生信息编辑</x-title>
    <div v-if="ready">
      <x-title v-if="student">{{
        `${student.grade}年级${student.class}班${student.xm}`
      }}</x-title>
      <modelform-uni
        :model="FormModel"
        :values="student"
        :sync-values="false"
        :success-url="query.redirect"
        :success-use-redirect="true"
        :action-url="actionUrl"
      ></modelform-uni>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const student = ref();
const FormModel = ref();
const query = useQuery();
const ready = ref();
const actionUrl = computed(
  () =>
    `/student/update/${query.id}?sync_to_hik=${process.env.NODE_ENV === "production"}`,
);
onLoad(async () => {
  const modelJson = await useGet(`/student/json`);
  FormModel.value = await Model.create_model_async(modelJson);
  student.value = await useGet(`/student/detail/${query.id}`);
  ready.value = true;
  console.log({ actionUrl });
});
</script>

<style scoped></style>
