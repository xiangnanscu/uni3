<template>
  <page-layout>
    <uni-card
      v-if="volplan"
      :title="volplan.title"
      :isFull="true"
      :is-shadow="false"
      :border="false"
      :extra="fromNow(volplan.ctime)"
    >
      <text class="uni-body">{{ volplan.content }}</text>
      <template v-slot:actions>
        <u-button type="primary">参加</u-button>
      </template>
    </uni-card>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      query: {},
      volplan: null
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
  },
  methods: {
    async fetchData(query) {
      const { data: volplan } = await this.$http.get(
        `/volplan/detail/${query.id}`
      );
      this.volplan = volplan;
    }
  }
};
</script>
