<template>
  <page-layout class="goddess-main">
    <uni-list :border="false">
      <navigator
        v-for="(item, index) in GoddessList"
        :key="index"
        :url="`/views/GoddessDetail?id=${item.id}`"
      >
        <uni-list-item
          :title="item.title"
          :showArrow="true"
          :rightText="fromNow(item.ctime)"
      /></navigator>
    </uni-list>
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
    async fetchData(query) {
      const records = await usePost(`/goddess/records`, {
        hide: false,
        status: "通过"
      });
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
