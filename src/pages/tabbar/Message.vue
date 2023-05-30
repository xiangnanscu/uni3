<template>
  <page-layout>
    <uni-notice-bar v-if="!messages.length" single text="没有收到任何信息" />
    <div v-else>
      <uni-list :border="false">
        <navigator
          v-for="(a, index) in messages"
          :url="`/pages/MessageDetail?id=${a.receiver.id}`"
          :key="index"
        >
          <uni-list-item>
            <template v-slot:header>
              <view class="slot-box">
                <image
                  class="message-avatar slot-image"
                  :src="a.receiver.avatar"
                  mode="widthFix"
                ></image>
              </view>
            </template>
            <template v-slot:body
              ><text class="message-body slot-box slot-text">{{
                a.chatList[0].content
              }}</text>
            </template>
            <template v-slot:footer>
              <view
                ><view class="message-header">{{ a.receiver.nickname }}</view>
                <view class="message-footer"
                  ><text>{{ fromNow(a.chatList[0].ctime) }}</text></view
                >
              </view></template
            >
          </uni-list-item>
        </navigator>
      </uni-list>
    </div>
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
      messages: []
    };
  },
  async onShow() {
    this.messages = [];
    console.log("Message.vue onShow");
    await this.fetchData();
  },
  methods: {
    async fetchData() {
      const {
        data: { records, total }
      } = await Http.get(`/message/my`);
      const messages = {};
      for (const e of records) {
        const receiver = e.target.id === this.user.id ? e.creator : e.target;
        const key = receiver.id;
        if (!messages[key]) {
          messages[key] = { receiver, chatList: [] };
        }
        messages[key].chatList.push(e);
      }
      this.messages = Object.values(messages);
      this.total = total;
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
  margin-right: 10px;
  margin-left: -10px;
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
}
</style>
