<template>
  <page-layout>
    <x-title>{{ type }}</x-title>
    <div v-if="NewsRecords.length">
      <uni-list :border="false">
        <x-navigator
          v-for="(item, index) in NewsRecords"
          :key="index"
          :url="`/views/NewsDetail?id=${item.id}`"
        >
          <uni-list-item
            :title="item.title"
            :showArrow="false"
            :rightText="utils.fromNow(item.ctime)"
        /></x-navigator>
      </uni-list>
    </div>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script>
export default defineComponent({
  data() {
    return {
      type: "",
      NewsRecords: [],
    };
  },
  async onLoad(opts) {
    this.type = opts.type || "今日热点";
    this.NewsRecords = await usePost(`/news/records`, { type: this.type });
  },
});
</script>

<style scoped></style>
