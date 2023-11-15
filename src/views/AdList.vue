<template>
  <page-layout>
    <x-title>杂文轩</x-title>
    <div v-if="NewsRecords.length">
      <uni-list :border="false">
        <x-navigator
          v-for="(item, index) in NewsRecords"
          :key="index"
          :url="`/views/AdDetail?id=${item.id}`"
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
      NewsRecords: [],
    };
  },
  async onLoad(opts) {
    this.NewsRecords = await usePost(`/ad/records`, { type: this.type });
  },
});
</script>

<style scoped></style>
