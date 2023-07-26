<template>
  <fui-sticky v-if="receiver">
    <div class="chat-head">
      {{ receiver.nickname }}
    </div>
  </fui-sticky>
  <page-layout>
    <view>
      <uni-list :border="false" class="chat-body">
        <template v-for="(chat, i) in messages" :key="chat.id">
          <uni-list-item v-if="chat.target.id === user.id" :border="false">
            <template v-slot:header>
              <view class="slot-box">
                <image
                  class="message-avatar slot-image"
                  :src="chat.creator.avatar"
                  mode="widthFix"
                ></image>
              </view>
            </template>
            <template v-slot:body
              ><text
                class="message-body slot-box slot-text"
                style="display: block; text-align: left"
                >{{ chat.content }}</text
              >
            </template>
          </uni-list-item>
          <uni-list-item v-else :border="false">
            <template v-slot:body
              ><text
                class="message-body slot-box slot-text"
                style="display: block; text-align: right"
                >{{ chat.content }}</text
              >
            </template>
            <template v-slot:footer>
              <view class="slot-box">
                <image
                  class="message-avatar slot-image-right"
                  :src="chat.creator.avatar"
                  mode="widthFix"
                ></image>
              </view>
            </template>
          </uni-list-item>
        </template>
      </uni-list>
      <x-chatbar
        v-if="showChatBar"
        v-model:modelValue="messageText"
        @sendMessage="sendMessage"
      />
    </view>
  </page-layout>
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
      showChatBar: false,
      showFloatPlus: true,
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
    await usePost("/message/clear_unread", { creator: this.receiverId });
    this.timerId = setInterval(async () => {
      await this.fetchNewChatRecords(this.latestId);
    }, 1000);
  },
  onUnload() {
    clearInterval(this.timerId);
  },
  async onShow() {
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
              console.log("res?.height", res?.height);
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
      this.toggleButton();
      uni.showToast({ icon: "none", title: "发送成功" });
    }
  }
};
</script>

<style scoped>
.chat {
  display: flex;
  flex-direction: column;
  height: 100vh;
}
.chat-head {
  padding: 10px;
  text-align: center;
  font-weight: bold;
  border-bottom: #eee solid 1px;
  background-color: #fff;
}
.chat-body {
  margin-bottom: 1em;
}
.slot-box {
  display: flex;
  flex-direction: row;
  align-items: center;
}
.slot-image {
  display: block;
  margin-right: 10px;
  width: 30px;
  height: 30px;
}
.slot-image-right {
  display: block;
  width: 30px;
  height: 30px;
}
.message-avatar {
  border-radius: 15px;
  width: 30px;
}
.slot-text {
  flex: 1;
  margin-right: 10px;
  font-size: 90%;
}
.message-body {
  padding: 2px;
}
</style>
