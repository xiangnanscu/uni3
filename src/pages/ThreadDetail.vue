<template>
  <page-layout>
    <view v-if="thread">
      <thread-head
        :thread="thread"
        :posts="posts"
        postCreateUrl="/post/create"
        threadOtherPrefix="/thread/other"
        fkName="thread_id"
        @appendPosts="posts.push($event)"
      ></thread-head>
      <thread-body :posts="posts"></thread-body>
    </view>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      thread: {},
      posts: [],
    };
  },
  async onLoad(query) {
    await this.fetchData(query);
  },
  methods: {
    async fetchData(query) {
      const { data: thread } = await this.$http.get(`/thread/${query.id}`);
      this.thread = thread;
      const { data: posts } = await this.$http.get(
        `/post/thread/${this.thread.id}`
      );
      this.posts = posts;
    },
  },
};
</script>

<style scoped></style>
