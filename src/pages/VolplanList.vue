<template>
  <page-layout class="volplan-main">
    <div v-if="VolplanRecords.length">
      <uni-list :border="false">
        <navigator
          v-for="(item, index) in VolplanRecords"
          :key="index"
          :url="`/pages/VolplanDetail?id=${item.id}`"
        >
          <uni-list-item
            :title="item.title"
            :showArrow="false"
            :rightText="fromNow(item.ctime)"
        /></navigator>
      </uni-list>
      <uni-pagination
        :total="total"
        @change="clickPage"
        :current="current"
        :pageSize="pageSize"
      />
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
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
      VolplanRecords: []
    };
  },
  async onLoad(query) {
    this.query = query;
    console.log({ query });
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
      } = await Http.get(
        `/volplan?page=${query.page || this.current}&pagesize=${
          query.pagesize || this.pageSize
        }`
      );
      this.VolplanRecords = records;
      this.total = total;
    }
  }
};
</script>

<style scoped>
.volplan-main {
}
</style>
