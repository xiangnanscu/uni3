<template>
  <page-layout>
    <x-title>学生进出记录</x-title>
    <div v-if="access_logs.length">
      <uni-list :border="false">
        <uni-list-item
          v-for="(log, i) of access_logs"
          :key="log.id"
          :title="`${i + 1}.${log.student_id__xm}-${utils.getWeChatMessageTime(
            log.access_time,
          )}`"
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
const toStudentForm = async (log) => {
  await utils.gotoPage({
    url: `/views/SchoolStudentAccessLogDetail`,
    query: { id: log.id },
  });
};
const oldestId = computed(() => {
  if (access_logs.value.length) {
    return access_logs.value[access_logs.value.length - 1].id;
  } else {
    return;
  }
});
const fetchOldRecords = async () => {
  const records = await usePost(`/student_access_log/records?limit=20`, {
    id__lt: oldestId.value,
  });
  if (records.length) {
    access_logs.value.push(...records);
  }
  uni.stopPullDownRefresh();
};
onReachBottom(fetchOldRecords);
onLoad(async () => {
  await fetchOldRecords();
});
</script>

<style scoped></style>
