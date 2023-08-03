<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="goddess-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>浏览：{{ record.views }}</div>
        <div>{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <video
        v-if="record.video"
        :src="'https:' + record.video"
        :show-mute-btn="true"
        controls
        style="width: 100%"
      ></video>
      <image
        v-if="record.pics[0]"
        :src="record.pics[0]"
        @click="previewImage(record.pics[0])"
        mode="widthFix"
        style="width: 100%"
      />
      <tinymce-text :html="record.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <generic-actions
      :target-id="record.id"
      target-model="goddess"
      style="width: 100%"
    >
      <image
        v-if="record?.creator"
        @click="onAddFriend(record.creator)"
        :src="`../static/img/tabbar/friend_add-taobao.png`"
        class="actions"
      ></image>
    </generic-actions>
    <div style="height: 2em"></div>
    <thread-body
      class="chat-body"
      :posts="posts"
      @deletePost="deletePost"
      @replyPost="replyPost"
      @replyPostComment="replyPostComment"
    ></thread-body>
    <fui-divider text="到底了" />
    <div style="height: 2em"></div>
    <div v-if="showChatBar">
      <x-chatbar
        v-model.trim:modelValue="messageText"
        @sendMessage="sendMessage"
      >
        <template #head>
          <div class="action-panel-title">
            回复：{{ messageType == "replyPost" ? post?.digest : record.title }}
          </div>
        </template>
      </x-chatbar>
    </div>
  </page-layout>
  <fui-fab
    v-if="showFloatPlus"
    :distance="30"
    position="right"
    :isDrag="true"
    @click="showChatBarReplyThread"
  ></fui-fab>
</template>

<script>
import MixinShare from "./MixinShare";
import MixinThreadPost from "./MixinThreadPost";

export default {
  mixins: [MixinShare, MixinThreadPost],
  data() {
    return {
      shareTitlePrefix: "【江安“新青年”】"
    };
  },
  methods: {
    async onAddFriend(id) {
      await utils.gotoPage(`/views/MyQrCode?q=/test/${id}`);
    },
    async fetchData(query) {
      this.record = await useGet(`/goddess/detail/${query.id}`);
      this.posts = await useGet(`/goddess_comment/goddess/${this.record.id}`);
    },
    async deletePost({ id }) {
      const { affected_rows } = await usePost(
        `/goddess_comment/delete_self/${id}`
      );
      if (affected_rows == 1) {
        this.posts = this.posts.filter((e) => e.id !== id);
        uni.showToast({ title: "成功删除" });
      }
    },
    async sendPost(content) {
      const { data: newPost } = await Http.post("/goddess_comment/create", {
        content,
        goddess_id: this.record.id
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
      const newComment = await usePost("/goddess_comment_comment/create", {
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
.actions {
  width: 25px;
  height: 25px;
}
.goddess-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
