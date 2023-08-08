<template>
  <view>
    <view class="thread-main">
      <div class="slot-box avatar-container">
        <navigator :url="`/views/Profile?id=${target.creator}`">
          <image
            class="post-avatar"
            :src="target.creator__avatar"
            mode="widthFix"
          ></image
        ></navigator>
      </div>
      <div style="padding: 2px">
        <div class="thread-nickname">{{ target.creator__nickname }}</div>
        <div class="thread-restinfo">{{ fromNow(target.ctime) }}</div>
      </div>
    </view>
    <uni-card
      :border="false"
      :isFull="true"
      :is-shadow="false"
      padding="10px 0px"
    >
      <template v-slot:title
        ><span class="thread-title">{{ target.title }}</span></template
      >
      <text user-select class="thread-content">{{ target.content }}</text>
      <x-album v-if="picsUrls.length" :urls="picsUrls" :columns="1"></x-album>
      <generic-actions :target="target" :target-model="targetModel" />
    </uni-card>
  </view>
</template>

<script setup>
const props = defineProps({
  target: { type: Object },
  targetModel: { type: String },
  posts: { type: Array }
});
const picsUrls = computed(() => props.target?.pics || []);
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
