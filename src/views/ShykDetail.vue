<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="news-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>发布于：{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <fui-preview :previewData="previewData"></fui-preview>
      <div>会议附件</div>
      <div v-for="(file, i) of record.attachments" :key="i">
        <a :href="file.url">{{ file.name }}</a>
      </div>
      <div style="height: 2em"></div>
      <template #actions> </template>
    </uni-card>
  </page-layout>
</template>

<script>
import MixinShare from "./MixinShare";
import MixinThreadPost from "./MixinThreadPost";

export default {
  mixins: [MixinShare, MixinThreadPost],
  data() {
    return {
      target_model: "shyk"
    };
  },
  computed: {
    status() {
      const now = new Date();
      return this.record.start_time;
    },
    previewData() {
      return {
        list: [
          {
            label: "会议状态",
            value: ""
          },
          {
            label: "时间",
            value: this.record.start_time?.slice(0, 16)
          },
          {
            label: "地点",
            value: this.record.address
          },
          {
            label: "类型",
            value: this.record.type
          }
        ]
      };
    }
  },
  methods: {}
};
</script>

<style scoped>
.news-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
