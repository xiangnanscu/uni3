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
        @replyPost="replyPost"
      ></thread-body>
      <fui-divider text="到底了" />
      <x-chatbar
        v-if="showChatBar"
        v-model.trim:modelValue="messageText"
        @sendMessage="sendMessage"
      />
    </view>
  </page-layout>
  <fui-fab
    v-if="showFloatPlus"
    :distance="30"
    position="right"
    :isDrag="true"
    @click="showChatBarReplyThread"
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
      showFloatPlus: true,
      showChatBar: false,
      messageType: "",
      messageText: "",
      post: null,
      posts: []
    };
  },
  methods: {
    replyPost(post) {
      this.messageType = "replyPost";
      this.post = post;
      this.showChatBar = true;
      this.showFloatPlus = false;
    },
    deletePost({ id }) {
      this.posts = this.posts.filter((e) => e.id !== id);
    },
    showChatBarReplyThread() {
      this.messageType = "replyThread";
      this.showChatBar = true;
      this.showFloatPlus = false;
    },
    resetChatBar() {
      this.messageText = "";
      this.messageType = "";
      this.showChatBar = false;
      this.showFloatPlus = true;
      this.post = null;
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
      if (this.messageType == "replyThread") {
        return await this.sendPost(content);
      } else if (this.messageType == "replyPost") {
        return await this.sendComment(content);
      }
    },
    async sendPost(content) {
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
      this.resetChatBar();
      this.scrollTo();
      uni.showToast({ icon: "none", title: "回帖成功" });
    },
    async sendComment(content) {
      const { data: newComment } = await Http.post("/post_comment/create", {
        content,
        post_id: this.post.id,
        post_comment_id: this.post.comment_id
      });
      if (!this.post.comments) {
        this.post.comments = [];
      }
      this.post.comments.push({
        id: newComment.id,
        content: newComment.content,
        post_id: this.post.id,
        post_comment_id: this.post.comment_id,
        creator: this.user.id,
        creator__nickname: this.user.nickname,
        ctime: newComment.ctime
      });
      this.resetChatBar();
      uni.showToast({ icon: "none", title: "评论成功" });
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
