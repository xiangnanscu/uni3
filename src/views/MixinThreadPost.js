export default {
  data() {
    return {
      showFloatPlus: true,
      showChatBar: false,
      messageType: "",
      messageText: "",
      post: null,
      comment: null,
      target_model: "",
      posts: []
    };
  },
  methods: {
    async fetchData(query) {
      this.record = await useGet(`/${this.target_model}/detail/${query.id}`);
      this.posts = await useGet(
        `/post/target/${this.target_model}/${this.record.id}`
      );
    },
    async deletePost({ id }) {
      const { affected_rows } = await usePost(`/post/delete_self/${id}`);
      if (affected_rows == 1) {
        this.posts = this.posts.filter((e) => e.id !== id);
        uni.showToast({ title: "成功删除" });
      }
    },
    async sendPost(content) {
      const newPost = await usePost("/post/create", {
        content,
        target_model: this.target_model,
        target_id: this.record.id
      });
      if (this.record.creator && this.record.creator !== this.user.id) {
        newPost.creator__nickname = this.user.nickname;
        newPost.creator__avatar = this.user.avatar;
        newPost.target_digest = utils.textDigest(this.record.title, 31);
        await usePost("/system_message/create", {
          type: "reply_thread",
          target_usr: this.record.creator,
          content: newPost
        });
      }
      this.posts.push({
        id: newPost.id,
        content: newPost.content,
        creator: this.user.id,
        creator__nickname: this.user.nickname,
        creator__avatar: this.user.avatar,
        ctime: newPost.ctime
      });
      this.resetChatBar();
      this.scrollTo();
      uni.showToast({ icon: "none", title: "回帖成功" });
    },
    async sendComment(content) {
      const newComment = await usePost("/post_comment/create", {
        content,
        post_id: this.post.id,
        post_comment_id: this.comment?.id
      });
      newComment.creator__nickname = this.user.nickname;
      newComment.creator__avatar = this.user.avatar;

      const notices = [];
      const alreadyNoticed = {}; // 避免重复通知
      if (this.comment && this.comment.creator !== this.user.id) {
        alreadyNoticed[this.comment.creator] = true;
        notices.push({
          type: "reply_post_comment",
          target_usr: this.comment.creator,
          content: {
            ...newComment,
            target_model: "comment",
            target_id: this.comment.id,
            target_digest: utils.textDigest(this.comment.content, 31)
          }
        });
      }
      if (
        !alreadyNoticed[this.post.creator] &&
        this.post.creator !== this.user.id
      ) {
        // 评论自己的帖子不用通知
        alreadyNoticed[this.post.creator] = true;
        notices.push({
          type: "reply_post",
          target_usr: this.post.creator,
          content: {
            ...newComment,
            target_model: "post",
            target_id: this.post.id,
            target_digest: utils.textDigest(this.post.content, 31)
          }
        });
      }
      if (
        this.record.creator &&
        !alreadyNoticed[this.record.creator] &&
        this.record.creator !== this.user.id
      ) {
        // 新闻和团委发布的新青年没有creator
        notices.push({
          type: "reply_thread",
          target_usr: this.record.creator,
          content: {
            ...newComment,
            target_model: this.target_model,
            target_id: this.record.id,
            target_digest: utils.textDigest(this.record.title, 31)
          }
        });
      }
      if (notices.length) {
        await usePost("/system_message/insert", notices);
      }
      if (!this.post.comments) {
        this.post.comments = [];
      }
      this.post.comments.push({
        id: newComment.id,
        content: newComment.content,
        post_id: this.post.id,
        post_comment_id: this.comment?.id,
        creator: this.user.id,
        creator__nickname: this.user.nickname,
        post_comment_id__creator__nickname: this.comment?.creator__nickname,
        ctime: newComment.ctime
      });
      this.resetChatBar();
      uni.showToast({ icon: "none", title: "评论成功" });
    },
    replyPost(post) {
      this.messageType = "replyPost";
      this.post = post;
      this.showChatBar = true;
      this.showFloatPlus = false;
    },
    replyPostComment({ post, comment }) {
      this.messageType = "replyPost";
      this.post = post;
      this.comment = comment;
      this.showChatBar = true;
      this.showFloatPlus = false;
    },
    showChatBarReplyThread() {
      this.checkLogin();
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
      this.comment = null;
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
