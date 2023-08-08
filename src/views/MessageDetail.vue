<template>
  <fui-sticky v-if="receiver" class="main-color">
    <div class="chat-head">
      {{ receiver.nickname }}
    </div>
  </fui-sticky>
  <div class="chat main-color">
    <div v-for="e in messages" :key="e.id">
      <div v-if="e.time" class="chat-time">{{ e.time }}</div>
      <div :class="`chat-item chat-item-${user.id === e.creator.id}`">
        <div class="chat-avatar">
          <image
            class="chat-avatar"
            :src="e.creator.avatar"
            mode="widthFix"
          ></image>
        </div>
        <div :class="`chat-bubble chat-bubble-${user.id === e.creator.id}`">
          <text>{{ e.content.repeat(1) }}</text>
        </div>
      </div>
    </div>
    <x-chatbar
      v-if="showChatBar"
      v-model:modelValue="messageText"
      @sendMessage="sendMessage"
    />
  </div>
  <fui-fab
    v-if="showFloatPlus"
    :distance="30"
    position="right"
    :isDrag="true"
    @click="toggleButton"
  ></fui-fab>
  <view class="bottom"></view>
</template>

<script>
export default {
  props: {},
  data() {
    return {
      showChatBar: true,
      showFloatPlus: false,
      messageText: "",
      receiverId: 0,
      receiver: null,
      timerId: null,
      messages: []
    };
  },
  mounted() {
    this.scrollTo();
  },
  async onLoad(query) {
    this.receiverId = Number(query.receiverId);
    this.timerId = setInterval(async () => {
      await this.fetchNewChatRecords(this.latestId);
    }, 1000);
  },
  onUnload() {
    clearInterval(this.timerId);
  },
  async onShow() {
    useBadgeNumber();
    await this.fetchData(this.receiverId);
  },
  computed: {
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
    },
    scrollTo() {
      this.$nextTick(() => {
        setTimeout(() => {
          const view = uni.createSelectorQuery().in(this).select(".chat-body");
          view
            .boundingClientRect((res) => {
              uni.pageScrollTo({
                duration: 200,
                scrollTop: res?.height || Infinity
              });
            })
            .exec();
        }, 100);
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
.main-color {
  background-color: #eee;
}
.chat {
  padding: 5px 10px;
  height: 100vh;
}
.chat-head {
  padding: 10px;
  text-align: center;
  font-weight: bold;
  border-bottom: #e0e0e0 solid 1px;
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
  background-color: #9cda62;
  margin-right: 0.5em;
}

.chat-bubble-false {
  background-color: white;
  margin-left: 0.5em;
}
.chat-bubble-true::before {
  position: absolute;
  right: -8px;
  top: 15px;
  content: "";
  border: 4px solid transparent;
  border-left-color: #9cda62;
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
