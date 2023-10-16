<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <x-title>进出详情</x-title>
      <fui-preview :previewData="previewData"></fui-preview>
      <image
        v-if="record.avatar"
        :src="record.avatar"
        mode="widthFix"
        style="width: 100%; margin: auto"
      />
      <template #actions> </template>
    </uni-card>
    <div style="height: 4em"></div>
  </page-layout>
</template>

<script>
import { repr } from "@/lib/utils.mjs";

export default {
  data() {
    return {
      disableJoinButton: false,
      record: null,
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  computed: {
    previewData() {
      return {
        list: [
          {
            label: "学生姓名",
            value: this.record.student_id.xm,
          },
          {
            label: "年级",
            value: this.record.student_id.grade,
          },
          {
            label: "班级",
            value: this.record.student_id.class,
          },
          {
            label: "进出时间",
            value: this.record.access_time?.slice(0, 16),
          },
        ],
      };
    },
  },
  methods: {
    async fetchData(query) {
      const record = await useGet(`/student_access_log/detail/${query.id}`);
      this.record = record;
    },
  },
};
</script>

<style scoped>
.volplan-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
