<template>
  <page-layout>
    {{ version }}
  </page-layout>
</template>

<script>
import { version } from "../../package.json";

export default {
  data() {
    return {
      version
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

<style scoped></style>
