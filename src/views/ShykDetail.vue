<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="news-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>发布于：{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <fui-preview :previewData="previewData"></fui-preview>
      <div>会议附件</div>
      <uni-list>
        <a
          class="link"
          v-for="(file, i) of record.attachments"
          :key="i"
          :href="file.url"
          >{{ i + 1 }} . {{ file.name }}</a
        >
      </uni-list>
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
      const start = new Date(this.record.start_time);
      const end = new Date(this.record.end_time);
      if (now > end) {
        return "已结束";
      } else if (now > start) {
        return "进行中";
      } else {
        return "待开始";
      }
    },
    previewData() {
      return {
        list: [
          {
            label: "会议状态",
            value: this.status
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
.link {
  margin: 8px;
  min-width: 8em;
}
.news-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
