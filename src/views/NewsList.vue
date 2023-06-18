<template>
  <page-layout>
    <div v-if="NewsRecords.length">
      <uni-list :border="false">
        <navigator
          v-for="(item, index) in NewsRecords"
          :key="index"
          :url="`/views/NewsDetail?id=${item.id}`"
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
import { usePost } from "@/composables/usePost";

export default defineComponent({
  data() {
    return {
      NewsRecords: []
    };
  },
  async onLoad() {
    const { data: NewsRecords } = await usePost(`/news/records`, {});
    this.NewsRecords = NewsRecords;
  }
});
</script>

<style scoped></style>
