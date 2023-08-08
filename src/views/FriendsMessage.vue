<template>
  <uni-list v-if="messages.length" :border="false">
    <uni-list-chat
      v-for="e in messages"
      :key="e.id"
      clickable
      @click="clickItem(e)"
      :title="e.receiver.nickname"
      :note="utils.textDigest(e.content, 10)"
      :avatar="e.receiver.avatar"
      badge-positon="left"
      :badge-text="selfUnread(e) ? 'dot' : ''"
      :time="utils.fromNow(e.ctime)"
    >
    </uni-list-chat>
  </uni-list>
  <uni-notice-bar v-else single text="没有收到任何信息" />
</template>

<script>
export default {
  props: ["messages"],
  data() {
    return {};
  },
  methods: {
    selfUnread(e) {
      return e.target.id == this.user.id && !e.readed;
    },
    async clickItem(e) {
      if (this.selfUnread(e)) {
        await usePost("/message/clear_unread", { creator: e.receiver.id });
      }
      await utils.gotoPage({
        url: `/views/MessageDetail?receiverId=${e.receiver.id}`
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
  width: 40px;
  height: 40px;
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
