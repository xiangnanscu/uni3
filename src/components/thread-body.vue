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
            <view class="post-body">
              <view class="post-header">
                <div>{{ post.creator__nickname }}</div>
                <div @click="togglePostActionPanel(post)">
                  <image
                    class="post-action-dot"
                    src="../static/img/tabbar/more-tpp.png"
                  />
                </div>
              </view>
              <view class="post-content">
                <text>{{ post.content }}</text>
              </view>
              <view class="post-footer"
                ><text
                  >第{{ index + 1 }}楼 {{ fromNow(post.ctime) }}</text
                ></view
              >
            </view>
            <view class="post-comment" v-if="post.comments">
              <template v-for="c in post.comments" :key="c.id">
                <p>{{ c.creator__nickname }}: {{ c.content }}</p>
              </template>
            </view>
          </template>
          <template v-slot:footer> </template>
        </uni-list-item>
      </uni-list>
      <fui-bottom-popup
        :maskClosable="true"
        :show="showPostActionPanel"
        @close="closePostActionPanel"
      >
        <div :border="false" :is-full="true" v-if="currentPost">
          <div class="action-panel-title">{{ postDigest(currentPost) }}</div>
          <view class="fui-custom__wrap">
            <uni-grid
              :column="isSelfPost(currentPost) ? 2 : 1"
              :show-border="false"
              :square="false"
              @change="change"
            >
              <uni-grid-item
                v-if="isSelfPost(currentPost)"
                @click="clickDelete"
              >
                <view class="grid-item-box" style="text-align: center">
                  <image
                    style="width: 35px; height: 35px"
                    src="../static/img/tabbar/delete-tpp.png"
                    class="actions"
                  ></image>
                  <view class="logo-text">删除</view>
                </view>
              </uni-grid-item>
              <uni-grid-item @click="commentPost(currentPost)">
                <view class="grid-item-box" style="text-align: center">
                  <image
                    style="width: 35px; height: 35px"
                    src="../static/img/tabbar/comment-tpp.png"
                    class="actions"
                  ></image>
                  <view class="logo-text">回复</view>
                </view>
              </uni-grid-item>
            </uni-grid>
          </view>
        </div>
      </fui-bottom-popup>
      <fui-modal
        :show="showDelete"
        descr="确定删除此回复帖?"
        maskClosable
        @click="confirmDelete"
        @cancel="cancelDelete"
      ></fui-modal>
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
    fkName: { type: String, default: `thread_id` },
    deleteUrlPrefix: { type: String, default: `post` }
  },
  data() {
    return {
      currentPost: null,
      showDelete: false,
      showPostActionPanel: false
    };
  },

  methods: {
    isSelfPost(post) {
      return this.user.id === post?.creator;
    },
    postDigest(post) {
      return post
        ? `${post.creator__nickname}: ${utils.abstractText(post.content, 15)}`
        : "";
    },
    async commentPost(post) {},
    async confirmDelete({ index, text }) {
      if (text == "确定") {
        const { affected_rows } = await usePost(
          `/${this.deleteUrlPrefix}/delete_self/${this.currentPost.id}`
        );
        if (affected_rows == 1) {
          this.$emit("deletePost", { id: this.currentPost.id });
          uni.showToast({ title: "成功删除" });
        }
      }
      this.showDelete = false;
    },
    cancelDelete(e) {
      console.log(e);
      this.showDelete = false;
    },
    closePostActionPanel(e) {
      console.log("closePostActionPanel");
      // 似乎只在点击空白关闭时触发
      this.showPostActionPanel = false;
      this.currentPost = null;
    },
    clickDelete() {
      this.showPostActionPanel = false;
      this.showDelete = true;
    },
    togglePostActionPanel(post) {
      this.showPostActionPanel = !this.showPostActionPanel;
      if (this.showPostActionPanel) {
        this.currentPost = post;
      } else {
        this.currentPost = null;
      }
    },
    changeOthers() {
      console.log("changeOthers");
    },
    change() {}
  }
};
</script>

<style scoped>
.post-comment {
  background-color: #eeecec;
  padding: 6px;
  border-radius: 3px;
}
.logo-text {
  font-size: 90%;
}
.action-panel-title {
  text-align: center;
  font-size: 90%;
  padding: 1em;
}
.post-action-dot {
  width: 20px;
  height: 20px;
}
.fui-custom__wrap {
  width: 100%;
  height: 220rpx;
  margin-top: 1em;
}
.post-header {
  color: #666;
  font-size: 75%;
  display: flex;
  justify-content: space-between;
  /* background-color: red; */
}
.post-footer {
  color: #666;
  /* background-color: red; */
  font-size: 70%;
  padding-top: 3px;
}
.post-body {
  width: 100%;
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
