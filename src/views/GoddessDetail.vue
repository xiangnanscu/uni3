<template>
  <page-layout v-if="goddess">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="goddess-title">{{ goddess.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>{{ utils.fromNow(goddess.ctime) }}</div>
      </x-subtitle>
      <tinymce-text :html="goddess.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <div style="height: 3em"></div>
    <x-bottom>
      <generic-actions
        :target-id="goddess.id"
        target-model="goddess"
        style="width: 100%"
      />
    </x-bottom>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      page: getCurrentPages().slice(-1)[0],
      goddess: null
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  onShareTimeline(options) {
    return {
      title: this.goddess?.title,
      path: this.page.$page.fullPath,
      imageUrl: ""
    };
  },
  onShareAppMessage(options) {
    return {
      title: this.goddess?.title,
      path: this.page.$page.fullPath,
      imageUrl: ""
    };
  },
  methods: {
    onTap(event) {
      console.log(event);
    },
    async fetchData(query) {
      const { data: goddess } = await Http.get(`/goddess/detail/${query.id}`);
      this.goddess = goddess;
    }
  }
};
</script>

<style scoped>
.goddess-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
