<template>
  <page-layout v-if="currentProfile">
    <uni-list :border="false">
      <uni-list-chat
        :avatar-circle="true"
        :title="currentProfile.nickname"
        :avatar="currentProfile.avatar"
        :note="currentProfile.intro"
      ></uni-list-chat>
    </uni-list>
    <div style="text-align: center">
      <button
        v-if="currentProfile.id !== user.id"
        plain="true"
        type="primary"
        size="mini"
        @click="$refs.popupMessage.open()"
      >
        私信
      </button>
    </div>

    <uni-list :border="false">
      <uni-list-item
        v-for="(item, index) in currentProfileThreads"
        :key="index"
        :to="`/pages/ThreadDetail?id=${item.id}`"
        :title="item.title"
        :rightText="fromNow(item.ctime)"
        :ellipsis="1"
        :showArrow="false"
      />
    </uni-list>

    <uni-popup
      ref="popupMessage"
      background-color="#fff"
      type="bottom"
      @change="currentMessage = ''"
    >
      <view style="padding: 15px">
        <div style="margin-bottom: 15px">{{ currentProfile.nickname }}:</div>
        <!-- <u-textarea
            v-model="currentMessage"
            height="50"
            :cursorSpacing="90"
          ></u-textarea> -->
        <!-- <uni-easyinput
            type="textarea"
            autoHeight
            v-model="currentMessage"
            placeholder="请输入内容"
          ></uni-easyinput> -->
        <textarea
          class="textarea"
          v-model="currentMessage"
          style="width: 100%"
          :cursorSpacing="90"
          :adjust-position="true"
        ></textarea>
        <u-button type="success" @click="sendMessage()" plain="true">
          发送
        </u-button></view
      >
    </uni-popup>
  </page-layout>
</template>

<script>
export default {
  props: {
    threadOtherPrefix: { type: String, default: `/thread/other` }
  },
  data() {
    return {
      currentProfile: null,
      currentProfileThreads: null,
      currentMessage: ""
    };
  },
  async onLoad(query) {
    console.log("onload", { query });
    this.query = query;
    await this.fetchData(query);
  },
  methods: {
    async sendMessage() {
      const { data } = await $Http.post(`/message/create`, {
        target: this.currentProfile.id,
        content: this.currentMessage
      });
      this.$refs.popupMessage.close();
      uni.showToast({ icon: "none", title: "发送成功" });
    },
    async fetchData(query) {
      const { data: threads } = await $Http.get(
        `/thread/other/${query.id}`
      );
      const { data: profile } = await $Http.get(
        `/usr/profile/${query.id}`
      );
      this.currentProfile = profile;
      this.currentProfileThreads = threads;
    }
  }
};
</script>
