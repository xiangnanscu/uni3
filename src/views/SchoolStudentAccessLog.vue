<template>
  <page-layout>
    <x-title>学生进出记录（{{ access_logs.length }}条）</x-title>
    <div v-if="access_logs.length">
      <uni-list :border="false">
        <uni-list-item
          v-for="(log, i) of access_logs"
          :key="log.id"
          :title="`${log.student_id__xm}-${utils.getWeChatMessageTime(log.access_time)}`"
          :thumb="log.avatar"
          thumb-size="lg"
          link
          @click="toStudentForm(log)"
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
