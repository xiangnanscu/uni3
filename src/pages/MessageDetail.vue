<template>
  <page-layout2>
    <view v-if="receiver" class="chat">
      <div class="chat-head">
        {{ receiver.nickname }}
      </div>
      <scroll-view :scroll-y="true" :scroll-top="99999" class="chat-body">
        <uni-list :border="false">
          <view v-for="(chat, i) in messages" :key="i">
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
          </view>
        </uni-list>
      </scroll-view>

      <u-row class="chat-foot" justify="space-between">
        <u-col span="10">
          <u-textarea
            autoHeight
            v-model:value="messageText"
            :cursorSpacing="10"
            placeholder="请输入内容"
          ></u-textarea>
        </u-col>
        <u-col span="2">
          <u-button type="success" @click="sendMessage"> 发送 </u-button>
        </u-col>
      </u-row>
    </view>
  </page-layout2>
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
    }
  },
  methods: {
    async sendMessage() {
      const { data } = await this.$http.post(`/message/create`, {
        target: this.chatId,
        content: this.messageText
      });
      this.gotoPage({ url: "/pages/tabbar/Message/Message" });
      uni.showToast({ icon: "none", title: "发送成功" });
    },
    async fetchData(chatId) {
      const {
        data: { records, total }
      } = await this.$http.get(`/message/chat?id=${chatId}`);
      this.messages = records;
      this.total = total;
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
  flex-grow: 1;
  overflow: scroll;
}
.chat-foot {
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
}
</style>
