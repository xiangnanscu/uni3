<template>
  <page-layout>
    <x-title>学生信息编辑</x-title>
    <div v-if="student && DetailModel">
      <x-title>{{ `${student.grade}年级${student.class}班${student.xm}` }}</x-title>
      <modelform-uni
        :model="DetailModel"
        :values="student"
        :sync-values="false"
        :success-url="query.redirect"
        :action-url="actionUrl"
      ></modelform-uni>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const student = ref();
const DetailModel = ref();
const query = useQuery();
const actionUrl = computed(
  () =>
    `/student/update/${query.id}?sync_to_hik=${process.env.NODE_ENV === "production"}`,
);
onLoad(async () => {
  DetailModel.value = Model.create_model(await useGet(`/student/json`));
  student.value = await useGet(`/student/detail/${query.id}`);
});
</script>

<style scoped></style>
