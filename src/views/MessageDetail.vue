<template>
  <div class="chat main-color">
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
export default {
  props: {},
  data() {
    return {
      wxChatColor: "#95ec69",
      wxChatBg: "#F2F2F2", // pages.json页面的style中可以配置微信小程序的背景色
      showChatBar: true,
      showFloatPlus: false,
      messageText: "",
      receiverId: 0,
      receiver: null,
      timerId: null,
      messages: []
    };
  },
  async onLoad(query) {
    this.receiverId = Number(query.receiverId);
    this.timerId = setInterval(async () => {
      await this.fetchNewChatRecords(this.latestId);
    }, 1000);
    setTimeout(this.scrollTo, 200);
  },
  onUnload() {
    clearInterval(this.timerId);
  },
  async onShow() {
    useBadgeNumber();
    await this.fetchData(this.receiverId);
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
    sender() {
      return {
        id: this.user.id,
        nickname: this.user.nickname,
        avatar: this.user.avatar
      };
    }
  },
  methods: {
    async fetchNewChatRecords(latestId) {
      const records = await usePost(
        `/message/chat_records?id=${this.receiverId}`,
        {
          id__gt: latestId
        },
        { disableShowLoading: true }
      );
      if (records.length) {
        this.messages.push(...records);
      }
    },
    async fetchData(receiverId) {
      this.messages = await usePost(
        `/message/chat_records?id=${receiverId}`,
        {}
      );
      this.receiver = await usePost(`/usr/query`, {
        get: { id: receiverId },
        select: ["id", "nickname", "avatar"]
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
      const { data } = await Http.post(`/message/create`, {
        target: this.receiverId,
        content
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

<style scoped>
page {
  /* pages.json页面的style中可以配置微信小程序的背景色, 但h5无效 */
  background-color: #f2f2f2;
}
.main-color {
  /* background-color: v-bind(wxChatBg); */
}
.chat {
  padding: 1em 10px 5em 10px;
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
