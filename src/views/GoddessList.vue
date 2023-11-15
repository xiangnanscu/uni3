<template>
  <page-layout>
    <x-title>江安“新青年”</x-title>
    <uni-list :border="false">
      <x-navigator
        v-for="(item, index) in GoddessList"
        :key="index"
        :url="`/views/GoddessDetail?id=${item.id}`"
      >
        <uni-list-item
          :title="item.title"
          :showArrow="true"
          :rightText="utils.fromNow(item.ctime)"
      /></x-navigator>
    </uni-list>
  </page-layout>
</template>

<script>
import { xml2js } from "xml-js";

// const res = xml2js(
//   `
//   <p class="MsoNormal">
//     啊<img
//     src="//lzwlkj.oss-cn-shenzhen.aliyuncs.com/jaqn/image/k9gs6rs3qnWIf7RQKGU_K.jpg"
//   />哦</p>
// `
// );
// console.log(res);
export default {
  data() {
    return {
      pageSize: 10,
      total: 0,
      current: 1,
      query: {},
      GoddessList: [],
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  methods: {
    async fetchData(query) {
      const records = await usePost(`/goddess/records`, {
        hide: false,
        status: "通过",
      });
      this.GoddessList = records;
      // this.total = total;
    },
  },
};
</script>

<style scoped></style>
