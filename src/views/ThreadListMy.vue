<template>
  <page-layout class="ThreadListMy-main">
    <uni-list :border="false" v-if="myThreadsList.length">
      <uni-list-item
        v-for="(item, index) in myThreadsList"
        :key="index"
        :to="`/views/ThreadDetail?id=${item.id}`"
        :title="item.title"
        :rightText="utils.fromNow(item.ctime)"
        :ellipsis="1"
        :showArrow="false"
      />
    </uni-list>
    <x-alert v-else title="没有记录"> </x-alert>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      query: {},
      myThreadsList: []
    };
  },

  async onLoad(query) {
    this.query = query;
  },
  async onShow() {
    this.myThreadsList = await this.getThreads();
  },
  methods: {
    async getThreads(query) {
      const { data } = await Http.get("/thread/my");
      return data;
    }
  }
};
</script>

<style scoped>
.ThreadListMy-main {
}
</style>
