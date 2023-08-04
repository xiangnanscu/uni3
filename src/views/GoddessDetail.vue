<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="goddess-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>浏览：{{ record.views }}</div>
        <div>{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <video
        v-if="record.video"
        :src="'https:' + record.video"
        :show-mute-btn="true"
        controls
        style="width: 100%"
      ></video>
      <image
        v-if="record.pics[0]"
        :src="record.pics[0]"
        @click="previewImage(record.pics[0])"
        mode="widthFix"
        style="width: 100%"
      />
      <tinymce-text :html="record.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <generic-actions
      :target-id="record.id"
      target-model="goddess"
      style="width: 100%"
    >
      <image
        v-if="record?.creator"
        @click="onAddFriend(record.creator)"
        :src="`../static/img/tabbar/friend_add-taobao.png`"
        class="actions"
      ></image>
    </generic-actions>
    <div style="height: 2em"></div>
    <thread-body
      class="chat-body"
      :posts="posts"
      @deletePost="deletePost"
      @replyPost="replyPost"
      @replyPostComment="replyPostComment"
    ></thread-body>
    <fui-divider text="到底了" />
    <div style="height: 2em"></div>
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
  </page-layout>
  <fui-fab
    v-if="showFloatPlus"
    :distance="30"
    position="right"
    :isDrag="true"
    @click="showChatBarReplyThread"
  ></fui-fab>
</template>

<script>
import MixinShare from "./MixinShare";
import MixinThreadPost from "./MixinThreadPost";

export default {
  mixins: [MixinShare, MixinThreadPost],
  data() {
    return {
      target_model: "goddess",
      shareTitlePrefix: "【江安“新青年”】"
    };
  },
  methods: {
    async onAddFriend(id) {
      await utils.gotoPage(`/views/MyQrCode?q=/test/${id}`);
    }
  }
};
</script>

<style scoped>
.actions {
  width: 25px;
  height: 25px;
}
.goddess-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
