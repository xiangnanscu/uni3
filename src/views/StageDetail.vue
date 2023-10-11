<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="stage-title">{{ record.name }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <image
        v-if="record.pics[0]"
        :src="record.pics[0]"
        mode="widthFix"
        style="width: 100%"
      />
      <fui-preview :previewData="previewData"></fui-preview>
      <tinymce-text :html="record.content" style="margin-top: 1em"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <x-button @click="joinVol">申请入住</x-button>
    <div style="height: 4em"></div>
    <x-bottom>
      <generic-actions :target="record" target-model="stage" style="width: 100%" />
    </x-bottom>
  </page-layout>
</template>

<script>
import { repr } from "@/lib/utils.mjs";
import MixinShare from "./MixinShare";

export default {
  mixins: [MixinShare],
  data() {
    return {
      disableJoinButton: false,
      record: null,
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  computed: {
    previewData() {
      return {
        list: [
          {
            label: "驿站地址",
            value: this.record.address,
          },
          {
            label: "联系方式",
            value: this.record.lxdh,
          },
          {
            label: "剩余床位男",
            value: this.record.male_count,
          },
          {
            label: "剩余床位女",
            value: this.record.female_count,
          },
        ],
      };
    },
  },
  methods: {
    async fetchData(query) {
      this.record = await useGet(`/stage/detail/${query.id}`);
    },
    async joinVol() {
      await utils.gotoPage({
        url: "/views/StageApply",
        query: {
          stage_id: this.record.id,
          stage_name: this.record.name,
        },
        redirect: true,
      });
    },
  },
};
</script>

<style scoped>
.stage-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
