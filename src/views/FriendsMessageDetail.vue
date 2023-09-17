<template>
  <div class="chat">
    <x-alert v-if="!maxMessageQueryCnt" title="超时请重新进入页面"></x-alert>
    <div v-for="e in timeHintMessages" :key="e.id">
      <div v-if="e.time" class="chat-time">
        {{ e.time }}
      </div>
      <div :class="`chat-item chat-item-${user.id === e.creator.id}`">
        <div class="chat-avatar">
          <image
            class="chat-avatar"
            :src="e.creator.avatar"
            mode="widthFix"
          ></image>
        </div>
        <div :class="`chat-bubble chat-bubble-${user.id === e.creator.id}`">
          <text>{{ e.content }}</text>
        </div>
      </div>
    </div>
    <x-chatbar
      v-if="showChatBar"
      v-model:modelValue="messageText"
      :focus="false"
      @sendMessage="sendMessage"
    />
  </div>
</template>

<script>
const wxNoticeDigestNumber = 17;
export default {
  props: {},
  data() {
    return {
      maxMessageQueryCnt: 3600,
      chatTrunkNumber: 6,
      wxChatColor: "#95ec69",
      wxChatBg: "#F2F2F2",
      showChatBar: true,
      showFloatPlus: false,
      messageText: "",
      receiverId: 0,
      receiver: null,
      timerId: null,
      updating: false,
      messages: []
    };
  },
  async onLoad(query) {
    this.receiverId = Number(query.receiverId);
    this.timerId = setInterval(async () => {
      if (this.maxMessageQueryCnt === 0) {
        clearInterval(this.timerId);
      } else if (!this.updating) {
        this.updating = true;
        this.maxMessageQueryCnt--;
        await this.fetchNewChatRecords(this.latestId);
        this.updating = false;
      }
    }, 1000);
    setTimeout(this.scrollTo, 200);
  },
  async onPullDownRefresh() {
    await this.fetchOldChatRecords(this.oldestId);
  },
  onUnload() {
    clearInterval(this.timerId);
  },
  async onShow() {
    await this.fetchData();
  },
  computed: {
    timeHintMessages() {
      const res = [];
      const now = new Date();
      let lastTime = null;
      for (const [i, e] of this.messages.entries()) {
        if (i === 0) {
          e.time = utils.getWeChatMessageTime(e.ctime, now);
          lastTime = new Date(e.ctime).getTime();
        } else {
          e.time = ""; // 重置,避免过多时间标记
          const currentTime = new Date(e.ctime).getTime();
          if (currentTime - lastTime > 60000) {
            e.time = utils.getWeChatMessageTime(e.ctime, now);
          }
          lastTime = currentTime;
        }
        res.push(e);
      }
      return res;
    },
    latestId() {
      return this.messages[this.messages.length - 1]?.id;
    },
    oldestId() {
      return this.messages[0]?.id;
    },
    sender() {
      return {
        id: this.user.id,
        nickname: this.user.nickname,
        avatar: this.user.avatar
      };
    }
  },
  methods: {
    addToMessages(list) {
      // 新消息送达和轮询之间的时间差可能会获取到重复记录
      for (const e of list) {
        if (!this.messages.find((f) => f.id === e.id)) {
          this.messages.push(e);
        } else {
          console.log("find!!");
        }
      }
    },
    async fetchChatRecords({ query, data, opts }) {
      const records = await usePost(
        `/message/chat_records?${utils.toQueryString(query)}`,
        data,
        { ...opts, disableShowLoading: true }
      );
      return records.reverse();
    },
    async fetchOldChatRecords(oldestId) {
      const records = await this.fetchChatRecords({
        query: { id: this.receiverId, limit: this.chatTrunkNumber },
        data: { id__lt: oldestId }
      });
      if (records.length) {
        this.messages = [...records, ...this.messages];
      }
      uni.stopPullDownRefresh();
    },
    async fetchNewChatRecords(latestId) {
      const records = await this.fetchChatRecords({
        query: { id: this.receiverId },
        data: { id__gt: latestId }
      });
      this.addToMessages(records);
    },
    async fetchData() {
      const records = await this.fetchChatRecords({
        query: { id: this.receiverId, limit: this.chatTrunkNumber }
      });
      this.messages = records;
      this.receiver = await usePost(`/usr/query`, {
        get: { id: this.receiverId },
        select: ["id", "nickname", "avatar", "openid"]
      });
      uni.setNavigationBarTitle({ title: this.receiver.nickname });
    },
    scrollTo() {
      this.$nextTick(() => {
        setTimeout(() => {
          uni.pageScrollTo({
            duration: 100,
            scrollTop: 10 ** 10 //Infinity只在h5有效,这里改成具体的值
          });
        }, 200);
      });
    },
    toggleButton() {
      this.showChatBar = this.showFloatPlus;
      this.showFloatPlus = !this.showChatBar;
    },
    async sendMessage(content) {
      if (!content) {
        uni.showToast({ title: "请输入内容", icon: "error" });
        return;
      }
      const data = await usePost(`/message/create`, {
        target: this.receiverId,
        content
      });
      await usePost(`/wx/broadcast?type=chat`, {
        page: `views/FriendsMessageDetail?receiverId=${this.user.id}`,
        openid: this.receiver.openid,
        content: utils.textDigest(content, wxNoticeDigestNumber),
        nickname: this.user.nickname
      });
      data.creator = this.sender;
      data.target = this.receiver;
      // console.log(this.messages.slice(-1), this.sender);
      this.messages.push(data);
      this.messageText = "";
      this.scrollTo();
      // this.toggleButton();
      uni.showToast({ icon: "none", title: "发送成功" });
    }
  }
};
</script>
<style>
page {
  /* pages.json页面的style中配置微信小程序的背景色无效 */
  background-color: #f2f2f2;
}
</style>
<style scoped>
.chat {
  padding: 1em 10px 5em 10px;
  background-color: transparent;
  /* min-height: 100vh; */
}
.chat-bottom {
  height: 2em;
}
.chat-time {
  text-align: center;
  font-size: 68.8%;
  color: #666;
  margin: 1em 0;
}

.chat-item {
  display: flex;
  align-items: top;
  margin-bottom: 1em;
}
.chat-item-true {
  flex-direction: row-reverse;
  justify-content: flex-start;
}
.chat-item-false {
  flex-direction: row;
  justify-content: flex-start;
}
.chat-avatar {
  width: 40px;
  height: 40px;
  border-radius: 5px;
}
.chat-bubble {
  position: relative;
  display: flex;
  align-items: center;
  border-radius: 4px;
  /* height: 40px; */
  padding: 0.5em;
  /* overflow-wrap: anywhere; */
  font-size: 90%;
}
.chat-bubble-true {
  background-color: v-bind(wxChatColor);
  margin-right: 0.8em;
}

.chat-bubble-false {
  background-color: white;
  margin-left: 0.8em;
}
.chat-bubble-true::before {
  position: absolute;
  right: -8px;
  top: 15px;
  content: "";
  border: 4px solid transparent;
  border-left-color: v-bind(wxChatColor);
}

.chat-bubble-false::after {
  position: absolute;
  left: -8px;
  top: 15px;
  content: "";
  border: 4px solid transparent;
  border-right-color: white;
}
</style>
