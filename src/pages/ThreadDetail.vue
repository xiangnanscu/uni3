<template>
  <page-layout>
    <view v-if="thread">
      <thread-head
        :thread="thread"
        :posts="posts"
        threadOtherPrefix="/thread/other"
        fkName="thread_id"
      ></thread-head>
      <thread-body :posts="posts"></thread-body>
    </view>
  </page-layout>
  <div class="thread-reply">
    <x-button @click="replyClick">回复</x-button>
  </div>
  <uni-popup ref="replyPopup" type="bottom" background-color="#fff">
    <div style="padding: 15px">
      <textarea
        focus
        height="50"
        :cursorSpacing="90"
        v-model="currentPost"
      ></textarea>
      <x-button @click="replyThread()">回复</x-button>
    </div>
  </uni-popup>
</template>

<script>
export default {
  data() {
    return {
      thread: null,
      currentPost: "",
      posts: []
    };
  },
  async onLoad(query) {
    await this.fetchData(query);
  },
  methods: {
    async fetchData(query) {
      const { data: thread } = await Http.get(`/thread/${query.id}`);
      this.thread = thread;
      const { data: posts } = await Http.get(`/post/thread/${this.thread.id}`);
      this.posts = posts;
    },
    async replyThread() {
      if (!this.currentPost.trim()) {
        return uni.showToast({ title: "必须输入内容", icon: "error" });
      }
      const { data: newPost } = await Http.post("/post/create", {
        content: this.currentPost,
        thread_id: this.thread.id
      });
      this.posts.push({
        id: newPost.id,
        content: newPost.content,
        creator: {
          id: this.user.id,
          nickname: this.user.nickname,
          avatar: this.user.avatar
        },
        ctime: newPost.ctime
      });
      this.$refs.replyPopup.close();
      uni.pageScrollTo({
        scrollTop: 2000000, //滚动到页面的目标位置（单位px）
        duration: 0 //滚动动画的时长，默认300ms，单位 ms
      });
    },
    replyClick() {
      this.$refs.replyPopup.open();
      this.currentPost = "";
    }
  }
};
</script>
<style scoped>
.thread-reply {
  position: fixed;
  bottom: 0px;
  background-color: aliceblue;
  width: 100%;
  text-align: center;
}
</style>
