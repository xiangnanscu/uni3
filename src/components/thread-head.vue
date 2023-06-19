<template>
  <page-layout>
    <view>
      <view class="thread-main">
        <div class="slot-box avatar-container">
          <navigator :url="`/views/Profile?id=${thread.creator.id}`">
            <image
              class="post-avatar"
              :src="thread.creator.avatar"
              mode="widthFix"
            ></image
          ></navigator>
        </div>
        <div style="padding: 2px">
          <div class="thread-nickname">{{ thread.creator.nickname }}</div>
          <div class="thread-restinfo">{{ fromNow(thread.ctime) }}</div>
        </div>
      </view>
      <uni-card
        :border="false"
        :isFull="true"
        :is-shadow="false"
        padding="10px 0px"
      >
        <template v-slot:title
          ><span class="thread-title">{{ thread.title }}</span></template
        >
        <text user-select class="thread-content">{{ thread.content }}</text>
        <x-album v-if="picsUrls.length" :urls="picsUrls" :columns="1"></x-album>
        <generic-actions :target-id="thread.id" target-model="thread" />
      </uni-card>
    </view>
  </page-layout>
</template>

<script setup>
const props = defineProps({
  thread: { type: Object },
  posts: { type: Array },
  postCreateUrl: { type: String, default: `/post/create` },
  threadOtherPrefix: { type: String, default: `/thread/other` },
  fkName: { type: String, default: `thread_id` }
});
const picsUrls = computed(() => props.thread?.pics || []);
</script>

<style scoped>
.actions {
  width: 25px;
  height: 25px;
}
.actions-container {
  display: flex;
  justify-content: space-around;
}
.textarea {
  /* width: 100%; */
  border: #eee 0px solid;
  padding: 10px;
}
.thread-main {
  display: flex;
  flex-direction: row;
  margin-bottom: 15px;
}
.thread-title {
  font-weight: bold;
  font-size: 110%;
}
.thread-content {
  color: black;
  font-size: 110%;
}
.thread-nickname {
  color: #666;
  font-size: 75%;
}
.thread-restinfo {
  color: #666;
  font-size: 70%;
}

.post-avatar {
  border-radius: 15px;
  width: 30px;
  height: 30px;
}
.avatar-container {
  width: 30px;
}

.thread-reply {
  padding: 15px;
}
.slot-box {
  margin-right: 5px;
}
</style>
