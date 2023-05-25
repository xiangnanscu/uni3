<template>
  <page-layout class="goddess-main">
    <uni-list :border="false">
      <uni-list-item
        v-for="(item, index) in GoddessList"
        :key="index"
        :title="item.title"
        :showArrow="false"
        :pageSize="pageSize"
        :rightText="fromNow(item.ctime)"
      />
    </uni-list>
    <uni-pagination :total="total" @change="clickPage" :current="current" />
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      pageSize: 10,
      total: 0,
      current: 1,
      query: {},
      GoddessList: []
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  methods: {
    async clickPage(e) {
      this.current = e.current;
      await this.fetchData({ page: this.current, pagesize: this.pageSize });
    },
    async fetchData(query) {
      const {
        data: { records, total }
      } = await $Http.get(
        `/goddess?page=${query.page || this.current}&pagesize=${
          query.pagesize || this.pageSize
        }`
      );
      this.GoddessList = records;
      this.total = total;
    }
  }
};
</script>

<style scoped>
.goddess-main {
  padding: 15px;
}
</style>
