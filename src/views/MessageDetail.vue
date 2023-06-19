<template>
  <page-layout>
    <view v-if="receiver">
      <div class="chat-head">
        {{ receiver.nickname }}
      </div>
      <!-- <scroll-view :scroll-y="true" :scroll-top="99999" class="chat-body">

      </scroll-view> -->
      <uni-list :border="false" class="chat-body">
        <template v-for="(chat, i) in messages" :key="chat.id">
          <uni-list-item
            v-if="chat.target.id === user.id"
            :border="false"
            :class="{ lastchat: i === messages.length - 1 }"
          >
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
          <uni-list-item
            v-else
            :border="false"
            :class="{ lastchat: i === messages.length - 1 }"
          >
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
      <x-chatbar v-model="messageText" @sendMessage="sendMessage" />
    </view>
  </page-layout>
</template>

<script>
export default {
  props: {
    pagesize: { type: Number, default: 10 },
    page: { type: Number, default: 1 }
  },
  data() {
    return {
      messageText: "",
      chatId: 0,
      messages: []
    };
  },
  mounted() {
    console.log("mounted");
    this.$nextTick(() => {
      const view = uni.createSelectorQuery().in(this).select(".lastchat");
      console.log({ view });
      uni.pageScrollTo({
        duration: 0,
        scrollTop: 9999
      });
      view
        .boundingClientRect((res) => {
          console.log("节点:", res);
          uni.pageScrollTo({
            duration: 0,
            scrollTop: res?.top
          });
        })
        .exec();
    });
  },
  async onLoad(query) {
    this.chatId = Number(query.id);
  },
  async onShow() {
    await this.fetchData(this.chatId);
  },
  computed: {
    receiver() {
      const e = this.messages[0];
      if (!e) {
        return null;
      }
      const res = e.creator.id === this.chatId ? e.creator : e.target;
      return res;
    },
    sender() {
      const e = this.messages[0];
      if (!e) {
        return null;
      }
      const res = e.creator.id === this.chatId ? e.target : e.creator;
      return res;
    }
  },
  methods: {
    async sendMessage(content) {
      if (!content) {
        uni.showToast({ title: "请输入内容", icon: "error" });
        return;
      }
      const { data } = await Http.post(`/message/create`, {
        target: this.chatId,
        content
      });
      data.creator = this.sender;
      data.target = this.receiver;
      // console.log(this.messages.slice(-1), this.sender);
      this.messages.push(data);
      this.messageText = "";
      uni.showToast({ icon: "none", title: "发送成功" });
    },
    async fetchData(chatId) {
      const {
        data: { records, total }
      } = await Http.get(`/message/chat?id=${chatId}`);
      this.messages = records;
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
}
.chat-body {
  overflow: scroll;
  margin-bottom: 6em;
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
