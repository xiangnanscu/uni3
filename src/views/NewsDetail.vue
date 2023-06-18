<template>
  <page-layout>
    <uni-card v-if="news" :isFull="true" :is-shadow="false" :border="false">
      <p class="news-title">{{ news.title }}</p>
      <tinymce-text :html="news.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      news: null
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  onShareTimeline(options) {
    console.log(options);
    const page = getCurrentPages().slice(-1)[0];
    console.log({ page });
    return {
      title: this.news.title,
      path: page.$page.fullPath,
      imageUrl: ""
    };
  },
  onShareAppMessage(options) {
    console.log(options);
    const page = getCurrentPages().slice(-1)[0];
    console.log({ page });
    return {
      title: this.news.title,
      path: page.$page.fullPath,
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
