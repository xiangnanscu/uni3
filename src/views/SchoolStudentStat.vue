<template>
  <page-layout>
    <x-title>学生统计情况（{{ students.length }}人）</x-title>
    <div v-if="students.length">
      <div>{{ `${grade}年级` }}</div>
      <uni-list
        v-for="[grade, classes] of Object.entries(grades)"
        :key="grade"
        :title="`${grade}年级`"
        :border="false"
      >
        <uni-list-item
          v-for="[cls, students] of Object.entries(classes)"
          :key="cls"
          :title="`${cls}班（${students.length}人）`"
          :showArrow="false"
          :rightText="utils.fromNow(item.ctime)"
        />
      </uni-list>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const students = ref([]);
onLoad(async () => {
  students.value = await usePost(`/student/records?select=grade&select=class`);
});
const grades = reactive({});
for (const s of students.value) {
  const grade = s.grade;
  const cls = s.class;
  if (!grades[grade]) {
    grades[grade] = {};
  }
  if (!grades[grade][cls]) {
    grades[grade][cls] = [];
  }
  grades[grade][cls].push(s);
}
</script>

<style scoped></style>
