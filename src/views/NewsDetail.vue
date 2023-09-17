<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="news-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>来源：{{ record.creator__name }}</div>
        <div>浏览：{{ record.views }}</div>
        <div>发布于：{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <video
        v-if="record.video"
        :src="'https:' + record.video"
        :show-mute-btn="true"
        controls
        style="width: 100%; margin: auto"
      ></video>
      <div style="width: 100%; margin: auto; margin-bottom: 1em">
        <image
          v-if="record.pics[0]"
          :src="record.pics[0]"
          @click="previewImage(record.pics[0])"
          mode="widthFix"
          style="width: 100%; margin: auto"
        />
      </div>
      <tinymce-text :html="record.content"></tinymce-text>
      <template #actions> </template>
    </uni-card>
    <generic-actions :target="record" target-model="news" style="width: 100%" />
    <div style="height: 2em"></div>
    <thread-body
      class="chat-body"
      :posts="posts"
      target-model="news"
      @deletePost="deletePost"
      @replyPost="replyPost"
      @replyPostComment="replyPostComment"
    ></thread-body>
    <fui-divider text="到底了" />
    <div style="height: 2em"></div>
    <div v-if="showChatBar">
      <x-chatbar
        v-model.trim:modelValue="messageText"
        @sendMessage="sendMessage"
        :title="`回复：${
          messageType == 'replyPost' ? post?.digest : record.title
        }`"
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
      target_model: "news"
    };
  },
  methods: {}
};
</script>

<style scoped>
.news-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
