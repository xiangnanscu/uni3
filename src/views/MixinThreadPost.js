export default {
  data() {
    return {
      showFloatPlus: true,
      showChatBar: false,
      messageType: "",
      messageText: "",
      post: null,
      posts: []
    };
  },
  methods: {
    replyPost(post) {
      this.messageType = "replyPost";
      this.post = post;
      this.showChatBar = true;
      this.showFloatPlus = false;
    },
    showChatBarReplyThread() {
      this.messageType = "replyThread";
      this.showChatBar = true;
      this.showFloatPlus = false;
    },
    resetChatBar() {
      this.messageText = "";
      this.messageType = "";
      this.showChatBar = false;
      this.showFloatPlus = true;
      this.post = null;
    },
    async sendMessage(content) {
      if (!content.trim()) {
        return uni.showToast({ title: "必须输入内容", icon: "error" });
      }
      if (this.messageType == "replyThread") {
        return await this.sendPost(content);
      } else if (this.messageType == "replyPost") {
        return await this.sendComment(content);
      }
    },
    scrollTo() {
      this.$nextTick(() => {
        setTimeout(() => {
          const view = uni.createSelectorQuery().in(this).select(".chat-body");
          view
            .boundingClientRect((res) => {
              console.log("res?.height", res?.height);
              uni.pageScrollTo({
                duration: 200,
                scrollTop: Infinity
              });
            })
            .exec();
        }, 100);
      });
    }
  }
};
