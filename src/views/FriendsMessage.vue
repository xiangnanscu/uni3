<template>
  <uni-list v-if="messages.length" :border="false">
    <navigator
      v-for="(a, index) in messages"
      :url="`/views/MessageDetail?receiverId=${a.receiver.id}`"
      :key="index"
    >
      <uni-list-item>
        <template v-slot:header>
          <view class="slot-box">
            <uni-badge
              :is-dot="true"
              :text="a.target.id == user.id && !a.readed ? 1 : 0"
              absolute="rightTop"
              size="normal"
              :offset2="[5, 5]"
            >
              <image
                class="message-avatar slot-image"
                :src="a.receiver.avatar"
                mode="widthFix"
              ></image>
            </uni-badge>
          </view>
        </template>
        <template v-slot:body
          ><text class="message-body slot-box slot-text">{{
            utils.textDigest(a.content, 10)
          }}</text>
        </template>
        <template v-slot:footer>
          <view style="text-align: right">
            <view class="message-header">{{ a.receiver.nickname }}</view>
            <view class="message-footer"
              ><text>{{ fromNow(a.ctime) }}</text></view
            >
          </view></template
        >
      </uni-list-item>
    </navigator>
  </uni-list>
  <uni-notice-bar v-else single text="没有收到任何信息" />
</template>

<script>
export default {
  props: ["messages"],
  data() {
    return {};
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
