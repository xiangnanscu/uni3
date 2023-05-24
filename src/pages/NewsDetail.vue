<template>
  <page-layout>
    <uni-card
      v-if="news"
      :title="news.title"
      :isFull="true"
      :is-shadow="false"
      :border="false"
      :extra="fromNow(news.ctime)"
    >
      <text class="uni-body">{{ news.content }}</text>
      <template v-slot:actions>
        <!-- <u-button type="primary"></u-button> -->
      </template>
    </uni-card>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      query: {},
      news: null,
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  methods: {
    async fetchData(query) {
      const { data: news } = await this.$http.get(`/news/${query.id}`);
      this.news = news;
    },
  },
};
</script>

<style scoped></style>
