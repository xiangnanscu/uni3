<template>
  <page-layout>
    <x-title>学生统计情况（{{ students.length }}人）</x-title>
    <div v-if="students.length">
      <template v-for="[grade, classes] of Object.entries(grades)" :key="grade">
        <x-title>{{ `${grade}年级` }}</x-title>
        <uni-list :title="`${grade}年级`" :border="false">
          <navigator
            v-for="[cls, cls_students] of Object.entries(classes)"
            :key="cls"
            :url="`/views/SchoolStudentList?class=${cls}&grade=${grade}`"
          >
            <uni-list-item
              :title="`${cls}班（${cls_students.length}人）`"
              :showArrow="false"
            />
          </navigator>
        </uni-list>
      </template>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script setup>
const students = ref([]);
const grades = reactive({});
onLoad(async () => {
  students.value = await usePost(`/student/records?select=grade&select=class`);
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
});
</script>

<style scoped></style>
