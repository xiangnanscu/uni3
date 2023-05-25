<template>
  <page-layout>
    <view>
      <view class="thread-main">
        <div class="slot-box avatar-container">
          <navigator :url="`/pages/Profile?id=${thread.creator.id}`">
            <image
              class="post-avatar"
              :src="thread.creator.avatar"
              mode="widthFix"
            ></image
          ></navigator>
        </div>
        <div style="padding: 2px">
          <div class="thread-nickname">{{ thread.creator.nickname }}</div>
          <div class="thread-restinfo">{{ fromNow(thread.ctime) }}</div>
        </div>
      </view>
      <uni-card
        :border="false"
        :isFull="true"
        :is-shadow="false"
        padding="10px 0px"
      >
        <template v-slot:title
          ><span class="thread-title">{{ thread.title }}</span></template
        >
        <text user-select class="thread-content">{{ thread.content }}</text>
        <u-album v-if="picsUrls.length" :urls="picsUrls"></u-album>
      </uni-card>

      <button class="button" type="primary" @click="replyClick" plain="true">
        <text class="button-text">回帖</text>
      </button>
    </view>
    <u-popup :show="showUs" @close="showUs = false">
      <div style="padding: 15px">
        <u-textarea
          height="50"
          :cursorSpacing="90"
          v-model="currentPost"
        ></u-textarea>
        <u-button type="success" @click="replyThread()" plain="true">
          回复
        </u-button>
      </div>
    </u-popup>
  </page-layout>
</template>

<script>
export default {
  props: {
    thread: { type: Object },
    posts: { type: Array },
    postCreateUrl: { type: String, default: `/post/create` },
    threadOtherPrefix: { type: String, default: `/thread/other` },
    fkName: { type: String, default: `thread_id` },
  },
  data() {
    return {
      currentPost: "",
      showUs: false,
    };
  },
  computed: {
    picsUrls() {
      return this.thread?.pics?.map((e) => e) || [];
    },
  },
  methods: {
    replyClick() {
      this.showUs = true;
      this.currentPost = "";
    },
    async replyThread() {
      const { data: newPost } = await $Http.post(this.postCreateUrl, {
        content: this.currentPost,
        [this.fkName]: this.thread.id,
      });
      this.showUs = false;
      this.$emit("appendPosts", {
        id: newPost.id,
        content: newPost.content,
        creator: {
          id: this.user.id,
          nickname: this.user.nickname,
          avatar: this.user.avatar,
        },
      });
    },
  },
};
</script>

<style scoped>
.textarea {
  /* width: 100%; */
  border: #eee 0px solid;
  padding: 10px;
}
.thread-main {
  display: flex;
  flex-direction: row;
  margin-bottom: 15px;
}
.thread-title {
  font-weight: bold;
  font-size: 110%;
}
.thread-content {
  color: black;
  font-size: 110%;
}
.thread-nickname {
  color: #666;
  font-size: 75%;
}
.thread-restinfo {
  color: #666;
  font-size: 70%;
}

.post-avatar {
  border-radius: 15px;
  width: 30px;
  height: 30px;
}
.avatar-container {
  width: 30px;
}

.thread-reply {
  padding: 15px;
}
.slot-box {
  margin-right: 5px;
}
</style>
