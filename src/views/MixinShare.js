export default {
  data() {
    return { record: null, shareTitlePrefix: "" };
  },
  onShareTimeline(options) {
    return this.shareData;
  },
  onShareAppMessage(options) {
    return this.shareData;
  },
  computed: {
    shareData() {
      return {
        title: this.shareTitlePrefix + (this.record?.title || ""),
        desc: this.desc,
        path: utils.getFullPath(),
        imageUrl: this.imageUrl,
      };
    },
    desc() {
      const content = this.record?.content;
      if (content && content[0] !== "<") {
        return utils.textDigest(content, 20);
      } else {
        return "";
      }
    },
    imageUrl() {
      const img = this.record?.pics?.[0];
      return img ? (img.startsWith("http") ? img : "https:" + img) : "";
    },
  },
  methods: {},
};
