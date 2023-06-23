<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="news-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>来源：{{ record.creator__name }}</div>
        <div>浏览：{{ record.views }}</div>
        <div>发布于：{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <tinymce-text :html="record.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <div style="height: 3em"></div>
    <x-bottom>
      <generic-actions
        :target-id="record.id"
        target-model="news"
        style="width: 100%"
      />
    </x-bottom>
  </page-layout>
</template>

<script>
import MixinShare from "./MixinShare";

export default {
  mixins: [MixinShare],
  data() {
    return {
      record: null
    };
  },
  methods: {
    onTap(event) {
      console.log(event);
    },
    async fetchData(query) {
      const { data: news } = await Http.get(`/news/detail/${query.id}`);
      this.record = news;
    }
  }
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
