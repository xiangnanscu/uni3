<template>
  <page-layout v-if="ready">
    <div v-if="messages.length">
      <uni-list :border="false">
        <navigator
          v-for="(a, index) in messages"
          :url="`/views/MessageDetail?receiverId=${a.receiver.id}`"
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
                utils.abstractText(a.content, 10)
              }}</text>
            </template>
            <template v-slot:footer>
              <view
                ><view class="message-header">{{ a.receiver.nickname }}</view>
                <view class="message-footer"
                  ><text>{{ fromNow(a.ctime) }}</text></view
                >
              </view></template
            >
          </uni-list-item>
        </navigator>
      </uni-list>
    </div>
    <uni-notice-bar v-else single text="没有收到任何信息" />
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      ready: false,
      messages: []
    };
  },
  async onShow() {
    this.messages = [];
    await this.fetchData();
  },
  onHide() {
    this.ready = false;
  },
  methods: {
    async fetchData() {
      const records = await useGet(`/message/chat_panel`);
      this.messages = records.map((e) => ({
        ...e,
        receiver: e.target.id === this.user.id ? e.creator : e.target
      }));
      this.ready = true;
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
