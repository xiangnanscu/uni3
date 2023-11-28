<template>
  <page-layout>
    <x-title>学生成绩</x-title>
    <div v-if="student_scores.length">
      <uni-list :border="false">
        <uni-list-item
          v-for="(log, i) of student_scores"
          :key="log.id"
          :title="`${log.title}`"
          :link="false"
          :right-text="`${utils.getWeChatMessageTime(log.ctime)}`"
          @click="toStudentForm(log)"
          :note="`${log.school_id__name}${log.class_id__name}:${log.student_id__xm}:${log.subject}:${log.score}`"
          :showArrow="false"
        />
      </uni-list>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const student_scores = ref([]);
const query = useQuery();
const page = usePage();
const toStudentForm = async (log) => {
  await utils.gotoPage({
    url: `/views/SchoolStudentScoreDetail`,
    query: { id: log.id },
  });
};
const oldestId = computed(() => {
  if (student_scores.value.length) {
    return student_scores.value[student_scores.value.length - 1].id;
  } else {
    return;
  }
});
const fetchOldRecords = async () => {
  const records = await usePost(`/student_score/records?limit=20`, {
    id__lt: oldestId.value,
  });
  if (records.length) {
    student_scores.value.push(...records);
  }
  uni.stopPullDownRefresh();
};
onReachBottom(fetchOldRecords);
onLoad(async () => {
  await fetchOldRecords();
});
</script>

<style scoped></style>
