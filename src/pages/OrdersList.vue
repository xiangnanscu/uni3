<template>
  <page-layout class="orders-main">
    <uni-list :border="false">
      <uni-list-item
        v-for="(item, index) in OrdersList"
        :key="index"
        :title="extractOrderInfo(item)"
        :showArrow="false"
        :pageSize="pageSize"
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
      OrdersList: []
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  methods: {
    extractOrderInfo(item) {
      return `${item.description} / ${item.total / 100}元 / ${
        item.trade_state_desc
      }`;
    },
    async clickPage(e) {
      this.current = e.current;
      await this.fetchData({ page: this.current, pagesize: this.pageSize });
    },
    async fetchData(query) {
      const {
        data: { records, total }
      } = await $Http.get(
        `/orders/mylist?page=${query.page || this.current}&pagesize=${
          query.pagesize || this.pageSize
        }`
      );
      this.OrdersList = records;
      this.total = total;
    }
  }
};
</script>
