<template>
  <div>
    <scroll-view :scroll-y="true" :scroll-top="99999">
      <uni-list>
        <uni-list-item v-for="(post, index) in posts" :key="index">
          <template v-slot:header>
            <view class="slot-box avatar-container">
              <navigator :url="`/views/Profile?id=${post.creator}`">
                <image
                  class="post-avatar"
                  :src="post.creator__avatar"
                  mode="widthFix"
                ></image
              ></navigator>
            </view>
          </template>
          <template v-slot:body>
            <view class="post-body"
              ><view class="post-header">{{ post.creator__nickname }}</view>
              <view class="post-content"
                ><text>{{ post.content }}</text></view
              >
              <view class="post-footer"
                ><text
                  >第{{ index + 1 }}楼 {{ fromNow(post.ctime) }}</text
                ></view
              >
            </view>
          </template>
          <template v-slot:footer> </template>
        </uni-list-item>
      </uni-list>
      <div style="height: 3em"></div>
    </scroll-view>
  </div>
</template>

<script>
export default {
  props: {
    thread: { type: Object },
    posts: { type: Array },
    postCreateUrl: { type: String, default: `/post/create` },
    threadOtherPrefix: { type: String, default: `/thread/other` },
    fkName: { type: String, default: `thread_id` }
  },
  data() {
    return {};
  },

  methods: {
    changeOthers() {
      console.log("changeOthers");
    },
    change() {}
  }
};
</script>

<style scoped>
.post-header {
  color: #666;
  font-size: 75%;
  /* background-color: red; */
}
.post-footer {
  color: #666;
  /* background-color: red; */
  font-size: 70%;
  padding-top: 3px;
}
.post-body {
  padding: 2px;
}
.post-avatar {
  border-radius: 15px;
  width: 30px;
  height: 30px;
}
.avatar-container {
  width: 30px;
}
.slot-box {
  margin-right: 5px;
}
</style>
