<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <p class="goddess-title">{{ record.title }}</p>
      <x-subtitle style="padding: 0.5em 0.5em">
        <div>浏览：{{ record.views }}</div>
        <div>{{ utils.fromNow(record.ctime) }}</div>
      </x-subtitle>
      <image
        v-if="record.pics[0]"
        :src="record.pics[0]"
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
    <thread-body
      class="chat-body"
      style="margin-top: 1em"
      :posts="posts"
      @deletePost="deletePost"
    ></thread-body>
    <x-chatbar
      v-if="showChatBar"
      v-model:modelValue="messageText"
      @sendMessage="sendMessage"
    />
    <div style="height: 3em"></div>
  </page-layout>
  <fui-fab
    v-if="showFloatPlus"
    :distance="30"
    position="right"
    :isDrag="true"
    @click="toggleButton"
  ></fui-fab>
</template>

<script>
import MixinShare from "./MixinShare";

export default {
  mixins: [MixinShare],
  data() {
    return {
      showChatBar: false,
      showFloatPlus: true,
      messageText: "",
      posts: [],
      record: null
    };
  },
  methods: {
    async sendMessage(content) {
      if (!content.trim()) {
        return uni.showToast({ title: "必须输入内容", icon: "error" });
      }
      const { data: newPost } = await Http.post("/goddess_comment/create", {
        content,
        goddess_id: this.record.id
      });
      this.posts.push({
        id: newPost.id,
        content: newPost.content,
        creator: this.user.id,
        creator__nickname: this.user.nickname,
        creator__avatar: this.user.avatar,
        ctime: newPost.ctime
      });
      this.messageText = "";
      this.scrollTo();
      this.toggleButton();
      uni.showToast({ icon: "none", title: "发送成功" });
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
    deletePost({ id }) {
      this.posts = this.posts.filter((e) => e.id !== id);
    },
    toggleButton() {
      this.showChatBar = this.showFloatPlus;
      this.showFloatPlus = !this.showChatBar;
    },
    async onAddFriend(id) {
      await utils.gotoPage(`/views/MyQrCode?q=/test/${id}`);
    },
    async fetchData(query) {
      const { data: goddess } = await Http.get(`/goddess/detail/${query.id}`);
      this.record = goddess;
      const { data: posts } = await Http.get(
        `/goddess_comment/goddess/${this.record.id}`
      );
      this.posts = posts;
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
