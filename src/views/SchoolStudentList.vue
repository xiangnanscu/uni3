<template>
  <page-layout>
    <x-title>学生统计情况（{{ students.length }}人）</x-title>
    <div v-if="students.length">
      <x-title>{{ `${query.grade}年级${query.class}班` }}</x-title>
      <uni-list :border="false">
        <uni-list-item
          v-for="(std, i) of students"
          :key="std.id"
          :title="std.xm"
          :thumb="std.avatar"
          thumb-size="lg"
          link
          @click="toStudentForm(std)"
          :showArrow="false"
        />
      </uni-list>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const students = ref([]);
const query = useQuery();
const page = usePage();
const toStudentForm = async (std) => {
  await utils.gotoPage({
    redirect: false,
    url: `/views/SchoolStudentForm`,
    query: { id: std.id, redirect: page.value.$page.fullPath },
  });
};
onLoad(async () => {
  students.value = await usePost(`/student/records?select=xm&select=avatar`, query);
});
</script>

<style scoped></style>
