<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="ad-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <image
        v-if="record.pics[0]"
        :src="record.pics[0]"
        mode="widthFix"
        style="width: 100%"
      />
      <tinymce-text :html="record.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <div style="height: 3em"></div>
    <x-bottom>
      <generic-actions
        :target-id="record.id"
        target-model="ad"
        style="width: 100%"
      />
    </x-bottom>
  </page-layout>
</template>

<script>
import MixinShare from "./MixinShare";

export default {
  mixins: [MixinShare],
  data() {
    return {
      record: null
    };
  },
  methods: {
    async fetchData(query) {
      const { data: ad } = await Http.get(`/ad/detail/${query.id}`);
      this.record = ad;
    }
  }
};
</script>

<style scoped>
.ad-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
