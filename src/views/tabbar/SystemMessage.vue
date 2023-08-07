<template>
  <PageLayout>
    <uni-list v-if="messages.length" :border="false">
      <uni-list-item
        v-for="e of messages"
        clickable
        @click="setAsRead(e)"
        :show-badge="!e.readed"
        :is-dot="true"
        badge-text="1"
        badge-type="error"
        :key="e.id"
        :title="`${e.content.creator__nickname}`"
        :note="e.note"
        showArrow
        :thumb="e.content.creator__avatar"
        thumb-size="lg"
        :rightText="e.ctime"
      >
      </uni-list-item>
    </uni-list>
    <uni-notice-bar v-else single text="没有收到任何信息" />
  </PageLayout>
</template>

<script>
const detailViewMap = {
  post: "PostDetail",
  comment: "CommentDetail",
  thread: "ThreadDetail",
  goddess: "GoddessDetail"
};
const modelMap = {
  goddess: "新青年",
  thread: "帖子",
  post: "回帖"
};
const actionTextMap = {
  thumb_up: "赞了你的",
  reply_thread: "回复了你的帖子",
  reply_post: "评论了你的回帖",
  reply_post_comment: "回复了你的评论"
};
export default {
  data() {
    return {
      messages: []
    };
  },
  async onShow() {
    await useBadgeNumber();
    this.messages = (await this.fetchData()).map((e) => {
      e.ctime = utils.fromNow(e.ctime);
      e.url = `/views/${
        detailViewMap[e.content.url_model || e.content.target_model]
      }?id=${e.content.url_id || e.content.target_id}&scrollId=post-${
        e.content.post_id || e.id
      }`;
      e.actionText = actionTextMap[e.type];
      e.note =
        e.type == "thumb_up"
          ? `${e.actionText}${modelMap[e.content.target_model] || ""}“${
              e.content.target_digest
            }”`
          : `${e.actionText}“${e.content.target_digest}”：\n${e.content.content}`;
      return e;
    });
  },
  methods: {
    async setAsRead(e) {
      await useGet(`/system_message/readed/${e.id}`);
      await utils.gotoPage({ url: e.url });
    },
    async fetchData() {
      return await usePost(`/system_message/records`, {
        target_usr: this.user.id
      });
    }
  }
};
</script>

<style scoped>
.popup-scrollable {
  overflow-y: scroll;
  height: 500rpx;
}
.slot-box {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.slot-image {
  display: block;
  /* margin-right: 10px; */
  /* margin-left: -10px; */
  width: 30px;
  height: 30px;
}
.slot-image-right {
  display: block;
  width: 30px;
  height: 30px;
}
.message-avatar2 {
  border-radius: 15px;
  width: 30px;
}
.slot-text {
  flex: 1;
  margin-right: 10px;
}
.message-header {
  color: #666;
  font-size: 70%;
}
.message-footer {
  color: #666;
  font-size: 60%;
  padding-top: 3px;
}
.message-body {
  padding: 2px;
  margin-left: 10px;
}
</style>
