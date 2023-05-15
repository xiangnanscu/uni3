<template>
  <page-layout>
    <uni-list :border="false">
      <navigator
        v-for="(item, index) in LoginRecords"
        :key="index"
        :url="`/pages/LoginDetail/LoginDetail?id=${item.id}`"
      >
        <uni-list-item
          :title="item.title"
          :showArrow="false"
          :rightText="fromNow(item.ctime)"
        />
      </navigator>
    </uni-list>
    <uni-pagination
      :total="total"
      @change="clickPage"
      :current="current"
    />
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
      LoginRecords: [],
    };
  },
  async onLoad(query) {
    this.query = query
    // await this.fetchData(query)
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
        `/login?page=${query.page || this.current}&pagesize=${query.pagesize || this.pageSize
        }`
      );
      this.LoginRecords = records;
      this.total = total;
    },
  },
};
</script>
<style scoped></style>