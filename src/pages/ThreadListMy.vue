<template>
  <page-layout class="ThreadListMy-main">
    <uni-list :border="false">
      <uni-list-item
        v-for="(item, index) in myThreadsList"
        :key="index"
        :to="`/pages/ThreadDetail/ThreadDetail?id=${item.id}`"
        :title="item.title"
        :rightText="fromNow(item.ctime)"
        :ellipsis="1"
        :showArrow="false"
      />
    </uni-list>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      query: {},
      myThreadsList: [],
    };
  },

  async onLoad(query) {
    this.query = query;
  },
  async onShow() {
    this.myThreadsList = await this.getThreads();
  },
  methods: {
    async getThreads(query) {
      const { data } = await this.$http.get("/thread/my");
      return data;
    },
  },
};
</script>

<style scoped>
.ThreadListMy-main {
}
</style>
