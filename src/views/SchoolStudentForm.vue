<template>
  <page-layout>
    <x-title>学生信息录入</x-title>
    <div v-if="ready">
      <!-- <x-title v-if="student">{{
        `${student.grade}年级${student.class}班${student.xm}`
      }}</x-title> -->
      <modelform-fui
        :model="FormModel"
        :values="student"
        :sync-values="false"
        :success-url="query.redirect"
        :success-use-redirect="true"
        @successPost="successPost"
        :action-url="actionUrl"
      ></modelform-fui>
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
    (query.id ? `/student/update/${query.id}` : `/student/register`) +
    `?sync_to_hik=${process.env.NODE_ENV === "production"}`,
);
const successPost = async (data) => {
  if (query.parent_id && !query.id) {
    await usePost(`/parent_student_relation/merge?key=parent_id&key=student_id`, [
      { parent_id: query.parent_id, student_id: data.id },
    ]);
  }
  await utils.gotoPage({
    url: query.redirect,
  });
};
onLoad(async () => {
  const modelJson = await useGet(`/student/regedit_json`);
  FormModel.value = await Model.create_model_async(modelJson);
  if (query.id) {
    student.value = await useGet(`/student/detail/${query.id}`);
  }
  ready.value = true;
});
</script>

<style scoped></style>
