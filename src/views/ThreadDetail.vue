<template>
  <page-layout>
    <view v-if="record">
      <thread-head
        :target="record"
        target-model="thread"
        :posts="posts"
      ></thread-head>
      <thread-body
        class="chat-body"
        :target="record"
        :posts="posts"
        :scroll-id="query.scrollId"
        target-model="thread"
        @deletePost="deletePost"
        @replyPost="replyPost"
        @replyPostComment="replyPostComment"
      ></thread-body>
      <fui-divider text="到底了" />
      <div v-if="showChatBar">
        <x-chatbar
          v-model.trim:modelValue="messageText"
          :title="`回复：${
            messageType == 'replyPost' ? post?.digest : record.title
          }`"
          @sendMessage="sendMessage"
        >
        </x-chatbar>
      </div>
    </view>
  </page-layout>
  <fui-fab
    v-if="showFloatPlus"
    :distance="30"
    position="right"
    :isDrag="true"
    @click="showChatBarReplyThread"
  ></fui-fab>
  <view class="bottom"></view>
</template>

<script setup>
// https://github.com/dcloudio/uni-app/issues/3097
// onShareTimeline
// onShareAppMessage
// useWxShare({ title: "帖子哈哈" });
</script>

<script>
import MixinShare from "./MixinShare";
import MixinThreadPost from "./MixinThreadPost";

export default {
  mixins: [MixinShare, MixinThreadPost],
  data() {
    return {
      target_model: "thread"
    };
  },
  computed: {
    notify_click_page() {
      return "views/ThreadDetail?id=" + this.query.id;
    }
  },
  methods: {}
};
</script>
<style scoped>
.action-panel-title {
  text-align: center;
  font-size: 80%;
  padding: 5px;
  background: #f8f8f8;
  color: #666;
}
.thread-reply {
  position: fixed;
  bottom: 0px;
  background-color: aliceblue;
  width: 100%;
  text-align: center;
}
</style>
