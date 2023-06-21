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

<script setup>
// https://github.com/dcloudio/uni-app/issues/3097
// onShareTimeline
// onShareAppMessage
// useWxShare({ title: "帖子哈哈" });
</script>

<script>
export default {
  data() {
    return {
      thread: null,
      currentPost: "",
      page: getCurrentPages().slice(-1)[0],
      posts: []
    };
  },
  async onLoad(query) {
    await this.fetchData(query);
  },
  onShareTimeline(options) {
    return {
      title: this.thread?.title,
      desc: this.thread?.content.slice(0, 20) + "...",
      path: this.page.$page.fullPath,
      imageUrl: this.imageUrl
    };
  },
  onShareAppMessage(options) {
    return {
      title: this.thread?.title,
      desc: this.thread?.content.slice(0, 20) + "...",
      path: this.page.$page.fullPath,
      imageUrl: this.imageUrl
    };
  },
  computed: {
    imageUrl() {
      const img = this.thread?.pics[0];
      return img
        ? img.startsWith("http")
          ? img
          : "https:" + this.news?.pics[0]
        : "";
    }
  },
  methods: {
    async fetchData(query) {
      const { data: thread } = await Http.get(`/thread/detail/${query.id}`);
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
        creator: this.user.id,
        creator__nickname: this.user.nickname,
        creator__avatar: this.user.avatar,
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
