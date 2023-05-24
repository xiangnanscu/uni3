<template>
  <page-layout>
    <uni-list :border="false">
      <uni-list-item
        v-for="(item, index) in FeeplanList"
        :key="index"
        :to="`/pages/FeeplanDetail/FeeplanDetail?id=${item.id}`"
        :showArrow="false"
        :title="item.title"
        :rightText="fromNow(item.ctime)"
      >
      </uni-list-item>
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
      FeeplanList: [],
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
        data: { records, total },
      } = await this.$http.get(
        `/feeplan?page=${query.page || this.current}&pagesize=${
          query.pagesize || this.pageSize
        }`
      );
      this.FeeplanList = records;
      this.total = total;
    },
  },
};
</script>
<style scoped>
.slot-box {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.footer {
  color: #666;
  font-size: 90%;
  padding-top: 3px;
}
</style>
