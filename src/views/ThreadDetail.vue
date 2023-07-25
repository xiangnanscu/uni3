<template>
  <page-layout>
    <view v-if="record">
      <thread-head
        :thread="record"
        :posts="posts"
        threadOtherPrefix="/thread/other"
        fkName="thread_id"
      ></thread-head>
      <thread-body
        class="chat-body"
        :posts="posts"
        @deletePost="deletePost"
      ></thread-body>
      <x-chatbar
        v-if="showChatBar"
        v-model:modelValue="messageText"
        @sendMessage="sendMessage"
      />
    </view>
  </page-layout>
  <fui-fab
    v-if="showFloatPlus"
    :distance="30"
    position="right"
    :isDrag="true"
    @click="toggleButton"
  ></fui-fab>
  <view class="bottom"></view>
</template>

<script setup>
// https://github.com/dcloudio/uni-app/issues/3097
// onShareTimeline
// onShareAppMessage
// useWxShare({ title: "帖子哈哈" });
</script>

<script>
import MixinShare from "./MixinShare";

export default {
  mixins: [MixinShare],
  data() {
    return {
      showChatBar: false,
      showFloatPlus: true,
      messageText: "",
      posts: []
    };
  },
  methods: {
    deletePost({ id }) {
      this.posts = this.posts.filter((e) => e.id !== id);
    },
    toggleButton() {
      this.showChatBar = this.showFloatPlus;
      this.showFloatPlus = !this.showChatBar;
    },
    async fetchData(query) {
      const { data: thread } = await Http.get(`/thread/detail/${query.id}`);
      this.record = thread;
      const { data: posts } = await Http.get(`/post/thread/${this.record.id}`);
      this.posts = posts;
    },
    async sendMessage(content) {
      if (!content.trim()) {
        return uni.showToast({ title: "必须输入内容", icon: "error" });
      }
      const { data: newPost } = await Http.post("/post/create", {
        content,
        thread_id: this.record.id
      });
      this.posts.push({
        id: newPost.id,
        content: newPost.content,
        creator: this.user.id,
        creator__nickname: this.user.nickname,
        creator__avatar: this.user.avatar,
        ctime: newPost.ctime
      });
      this.messageText = "";
      this.scrollTo();
      this.toggleButton();
      uni.showToast({ icon: "none", title: "发送成功" });
    },
    scrollTo() {
      this.$nextTick(() => {
        setTimeout(() => {
          const view = uni.createSelectorQuery().in(this).select(".chat-body");
          view
            .boundingClientRect((res) => {
              console.log("res?.height", res?.height);
              uni.pageScrollTo({
                duration: 200,
                scrollTop: res?.height || Infinity
              });
            })
            .exec();
        }, 100);
      });
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
