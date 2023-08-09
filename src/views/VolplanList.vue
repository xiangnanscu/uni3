<template>
  <page-layout>
    <x-title>志愿服务</x-title>
    <div v-if="VolplanRecords.length">
      <uni-list :border="false">
        <navigator
          v-for="(item, index) in VolplanRecords"
          :key="index"
          :url="`/views/VolplanDetail?id=${item.id}`"
        >
          <uni-list-item
            :title="item.title"
            :showArrow="false"
            :rightText="fromNow(item.ctime)"
        /></navigator>
      </uni-list>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      query: {},
      VolplanRecords: []
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  methods: {
    async fetchData(query) {
      const records = await usePost(`/volplan/records`, { status: "通过" });
      this.VolplanRecords = records;
    }
  }
};
</script>

<style scoped>
.volplan-main {
}
</style>
