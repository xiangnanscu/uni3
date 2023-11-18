<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <x-title>{{ record.stage__name }}</x-title>
      <fui-preview :previewData="previewData"></fui-preview>
      <x-title>身份证</x-title>
      <image
        v-if="record.sfz_img"
        :src="record.sfz_img"
        mode="widthFix"
        style="width: 100%; margin: auto"
      />
      <x-title>毕业证书/学位证书/学士证</x-title>
      <image
        v-if="record.zs_img"
        :src="record.zs_img"
        mode="widthFix"
        style="width: 100%; margin: auto"
      />
      <template #actions> </template>
    </uni-card>
    <div style="height: 4em"></div>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      previewNames: [
        "ctime",
        "status",
        "message",
        "xm",
        "sfzh",
        "lxdh",
        "enter_date",
        "leave_date",
        "zzmm",
        "jg",
        "jkzk",
        "byyx",
        "zy",
        "xl",
        "xw",
        "bysj",
        "jyzt",
        "qzyxhy",
        "grjj",
      ],
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
        list: this.previewNames.map((e) => ({
          label: this.modelJson.fields[e]?.label,
          value: this.record[e],
        })),
      };
    },
  },
  methods: {
    async fetchData(query) {
      this.modelJson = await useGet(`/stage_apply/json`);
      this.record = await useGet(`/stage_apply/detail/${query.id}`);
    },
  },
};
</script>

<style scoped></style>
