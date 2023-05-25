<template>
  <page-layout class="goddess-main">
    <view v-if="goddess">
      <thread-head
        :thread="goddess"
        :posts="goddessComments"
        postCreateUrl="/goddess_comment/create"
        threadOtherPrefix="/thread/other"
        fkName="goddess_id"
        @appendPosts="goddessComments.push($event)"
      ></thread-head>
      <thread-body :posts="goddessComments"></thread-body>
    </view>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      goddess: null,
      goddessComments: []
    };
  },
  async onLoad(query) {
    await this.fetchData(query);
  },
  methods: {
    async fetchData(query) {
      const { data: goddess } = await Http.get(`/goddess/detail/${query.id}`);
      this.goddess = goddess;
      const { data: goddessComments } = await Http.get(
        `/goddess_comment/goddess/${this.goddess.id}`
      );
      console.log({ goddessComments });
      this.goddessComments = goddessComments;
    }
  }
};
</script>

<style scoped>
.goddess-main {
  padding: 15px;
}
</style>
