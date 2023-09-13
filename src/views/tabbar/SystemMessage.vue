<template>
  <button hover-class="button-hover" @click="subsribeReply">订阅</button>
  <uni-list v-if="messages.length" :border="false">
    <uni-list-chat
      v-for="e of messages"
      clickable
      @click="setAsRead(e)"
      :key="e.id"
      :title="`${e.content.creator__nickname}`"
      :note="e.note"
      :avatar="e.content.creator__avatar"
      badge-positon="left"
      :badge-text="e.readed ? '' : 'dot'"
      :time="e.ctime"
    >
    </uni-list-chat>
  </uni-list>
  <uni-notice-bar v-else single text="没有收到任何信息" />
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
  async onMounted() {},
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
          : `${e.actionText}“${e.content.target_digest}”：${e.content.content}`;
      return e;
    });
  },
  methods: {
    async subsribeReply() {
      const res = await uni.requestSubscribeMessage({
        tmplIds: ["xLBpBRv29raUd6H9rQWgrEs3HIiyDHWgbcV3Yy2JKko"]
      });
      if (res.xLBpBRv29raUd6H9rQWgrEs3HIiyDHWgbcV3Yy2JKko == "accept") {
        console.log("用户同意");
      }
      console.log(res);
    },
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
:deep(.uni-ellipsis) {
  /* 通知正文字数换行显示 */
  white-space: inherit;
}
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
