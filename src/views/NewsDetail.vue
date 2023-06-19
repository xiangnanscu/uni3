<template>
  <page-layout v-if="news">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="news-title">{{ news.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>来源：{{ news.creator.name }}</div>
        <div>{{ utils.fromNow(news.ctime) }}</div>
      </x-subtitle>
      <tinymce-text :html="news.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <div style="height: 3em"></div>
    <x-bottom>
      <generic-actions
        :target-id="news.id"
        target-model="news"
        style="width: 100%"
      />
    </x-bottom>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      page: getCurrentPages().slice(-1)[0],
      news: null
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  onShareTimeline(options) {
    return {
      title: this.news?.title,
      path: this.page.$page.fullPath,
      imageUrl: ""
    };
  },
  onShareAppMessage(options) {
    return {
      title: this.news?.title,
      path: this.page.$page.fullPath,
      imageUrl: ""
    };
  },
  methods: {
    onTap(event) {
      console.log(event);
    },
    async fetchData(query) {
      const { data: news } = await Http.get(`/news/detail/${query.id}`);
      this.news = news;
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
