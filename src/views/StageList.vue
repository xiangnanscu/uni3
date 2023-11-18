<template>
  <page-layout>
    <x-title>青年驿站</x-title>
    <div v-if="StageRecords.length">
      <uni-list :border="false">
        <x-navigator
          v-for="(item, index) in StageRecords"
          :key="index"
          :url="`/views/StageDetail?id=${item.id}`"
        >
          <uni-list-item
            :title="item.name"
            :showArrow="false"
            :rightText="utils.fromNow(item.ctime)"
        /></x-navigator>
      </uni-list>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
    <x-title>申请记录</x-title>
    <div v-if="StageApplyRecords.length">
      <uni-list :border="false">
        <x-navigator
          v-for="(item, index) in StageApplyRecords"
          :key="index"
          :url="`/views/StageApplyDetail?id=${item.id}`"
        >
          <uni-list-item
            :title="item.stage__name"
            :showArrow="false"
            :rightText="utils.fromNow(item.ctime)"
        /></x-navigator>
      </uni-list>
    </div>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      query: {},
      StageRecords: [],
      StageApplyRecords: [],
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  methods: {
    async fetchData(query) {
      this.StageRecords = await usePost(`/stage/records`, {});
      this.StageApplyRecords = await usePost(`/stage_apply/records_my`, {});
    },
  },
};
</script>

<style scoped>
.stage-main {
}
</style>
