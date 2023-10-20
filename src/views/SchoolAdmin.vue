<template>
  <page-layout>
    <x-title>校方管理</x-title>
    <div v-if="access_logs.length">
      <uni-list :border="false">
        <uni-list-item
          title="录入学生"
          thumb-size="lg"
          link
          to="/views/SchoolStudentRegedit"
          :showArrow="false"
        />
        <!-- <uni-list-item
          title="设定校领导"
          thumb-size="lg"
          link
          to="/views/SchoolHome"
          :showArrow="false"
        />
        <uni-list-item
          title="设定年级主任"
          thumb-size="lg"
          link
          to="/views/SchoolHome"
          :showArrow="false"
        /> -->
        <uni-list-item
          title="设定班主任"
          thumb-size="lg"
          link
          to="/views/SchoolTeacherRegedit"
          :showArrow="false"
        />
        <uni-list-item
          title="设定门卫"
          thumb-size="lg"
          link
          to="/views/SchoolHome"
          :showArrow="false"
        />
      </uni-list>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const access_logs = ref([]);
const query = useQuery();
const page = usePage();
const toStudentForm = async (std) => {
  await utils.gotoPage({
    url: `/views/SchoolStudentAccessLogDetail`,
    query: { id: std.id },
  });
};
onLoad(async () => {
  access_logs.value = await usePost(`/student_access_log/records`);
});
</script>

<style scoped></style>
