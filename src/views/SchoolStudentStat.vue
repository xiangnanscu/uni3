<template>
  <page-layout>
    <view class="search-bar">
      <!-- <uni-easyinput
        suffixIcon="search"
        v-model="searchValue"
        placeholder="请输入查找内容."
        iconClick="onClick"
      ></uni-easyinput> -->
    </view>
    <x-title>学生统计情况（{{ students.length }}人）</x-title>
    <div v-if="students.length">
      <template v-for="[grade, classes] of Object.entries(grades)" :key="grade">
        <x-title>{{ `${grade}年级` }}</x-title>
        <uni-list :title="`${grade}年级`" :border="false">
          <x-navigator
            v-for="[cls, cls_students] of Object.entries(classes)"
            :key="cls"
            :url="`/views/SchoolStudentList?class=${cls}&grade=${grade}`"
          >
            <uni-list-item
              :title="`${cls}班（${cls_students.length}人）`"
              :showArrow="false"
            />
          </x-navigator>
        </uni-list>
      </template>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
    <fui-fab
      :distance="30"
      position="right"
      :isDrag="true"
      @click="utils.gotoPage('SchoolStudentRegedit')"
    ></fui-fab>
  </page-layout>
</template>

<script setup>
const students = ref([]);
const grades = reactive({});
const searchValue = ref("");
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
