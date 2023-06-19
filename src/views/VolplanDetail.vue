<template>
  <page-layout v-if="volplan">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="volplan-title">{{ volplan.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>{{ utils.fromNow(volplan.ctime) }}</div>
      </x-subtitle>
      <x-button>我要参加</x-button>
      <tinymce-text :html="volplan.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <div style="height: 3em"></div>
    <x-bottom>
      <generic-actions
        :target-id="volplan.id"
        target-model="volplan"
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
      volplan: null
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  onShareTimeline(options) {
    return {
      title: this.volplan?.title,
      path: this.page.$page.fullPath,
      imageUrl: ""
    };
  },
  onShareAppMessage(options) {
    return {
      title: this.volplan?.title,
      path: this.page.$page.fullPath,
      imageUrl: ""
    };
  },
  methods: {
    onTap(event) {
      console.log(event);
    },
    async fetchData(query) {
      const { data: volplan } = await Http.get(`/volplan/detail/${query.id}`);
      this.volplan = volplan;
    }
  }
};
</script>

<style scoped>
.volplan-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
