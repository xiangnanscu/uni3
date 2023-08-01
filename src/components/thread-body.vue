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
                <div
                  @click="togglePostActionPanel(post)"
                  class="post-action-dot"
                >
                  ···
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
          </template>
          <template v-slot:footer> </template>
        </uni-list-item>
      </uni-list>
      <fui-bottom-popup
        :maskClosable="true"
        :show="showPostActionPanel"
        @close="closePostActionPanel"
      >
        <view class="fui-custom__wrap">
          <div v-if="currentPost?.creator == user.id" @click="clickDelete">
            <div>
              <image
                style="width: 35px; height: 35px"
                src="../static/img/tabbar/delete-tpp.png"
                class="actions"
              ></image>
            </div>
            <span>删除</span>
          </div>
        </view>
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
  setup() {
    const user = useUser();
    return {
      user
    };
  },
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
      this.showPostActionPanel = false;
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
.post-action-dot {
  font-size: 200%;
}
.fui-custom__wrap {
  width: 100%;
  height: 520rpx;
  display: flex;
  align-items: center;
  justify-content: center;
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
