<template>
  <view style="padding: 0 5px">
    <view class="thread-main">
      <div class="slot-box avatar-container">
        <x-navigator :url="`/views/Profile?id=${target.creator}`">
          <image class="post-avatar" :src="target.creator__avatar" mode="widthFix"></image
        ></x-navigator>
      </div>
      <div style="padding: 2px">
        <div class="thread-nickname">{{ target.creator__nickname }}</div>
        <div class="thread-restinfo">{{ utils.fromNow(target.ctime) }}</div>
      </div>
    </view>
    <div class="x-card">
      <div class="thread-title">{{ target.title }}</div>
      <x-text class="thread-content" :text="target.content"></x-text>
      <x-album v-if="picsUrls.length" :urls="picsUrls" :columns="1"></x-album>
      <generic-actions :target="target" :target-model="targetModel" />
    </div>
  </view>
</template>

<script setup>
const props = defineProps({
  target: { type: Object },
  targetModel: { type: String },
  posts: { type: Array },
});
const picsUrls = computed(() => props.target?.pics || []);
</script>

<style scoped>
.x-card {
  padding: 5px 0px;
}
.thread-main {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin-bottom: 15px;
}
.thread-title {
  font-weight: bold;
  font-size: 150%;
  margin-bottom: 1em;
}
.thread-content {
  color: black;
  font-size: 100%;
  line-height: 150%;
}
.thread-nickname {
  color: #666;
  font-size: 90%;
  font-weight: bold;
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
