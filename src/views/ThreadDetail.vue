<template>
  <page-layout>
    <view v-if="record">
      <thread-head
        :thread="record"
        :posts="posts"
      ></thread-head>
      <thread-body
        class="chat-body"
        :posts="posts"
        @deletePost="deletePost"
        @replyPost="replyPost"
        @replyPostComment="replyPostComment"
      ></thread-body>
      <fui-divider text="到底了" />
      <div v-if="showChatBar">
        <x-chatbar
          v-model.trim:modelValue="messageText"
          @sendMessage="sendMessage"
        >
          <template #head>
            <div class="action-panel-title">
              回复：{{
                messageType == "replyPost" ? post?.digest : record.title
              }}
            </div>
          </template>
        </x-chatbar>
      </div>
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
import MixinThreadPost from "./MixinThreadPost";

export default {
  mixins: [MixinShare, MixinThreadPost],
  data() {
    return {};
  },
  methods: {
    async fetchData(query) {
      const { data: thread } = await Http.get(`/thread/detail/${query.id}`);
      this.record = thread;
      const { data: posts } = await Http.get(`/post/thread/${this.record.id}`);
      this.posts = posts;
    },
    async deletePost({ id }) {
      const { affected_rows } = await usePost(`/post/delete_self/${id}`);
      if (affected_rows == 1) {
        this.posts = this.posts.filter((e) => e.id !== id);
        uni.showToast({ title: "成功删除" });
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
        post_comment_id: this.comment.id
      });
      if (!this.post.comments) {
        this.post.comments = [];
      }
      this.post.comments.push({
        id: newComment.id,
        content: newComment.content,
        post_id: this.post.id,
        post_comment_id: this.comment.id,
        creator: this.user.id,
        creator__nickname: this.user.nickname,
        post_comment_id__creator__nickname:this.comment.creator__nickname,
        ctime: newComment.ctime
      });
      this.resetChatBar();
      uni.showToast({ icon: "none", title: "评论成功" });
    }
  }
};
</script>
<style scoped>
.action-panel-title {
  text-align: center;
  font-size: 80%;
  padding: 5px;
  background: #f8f8f8;
  color: #666;
}
.thread-reply {
  position: fixed;
  bottom: 0px;
  background-color: aliceblue;
  width: 100%;
  text-align: center;
}
</style>
