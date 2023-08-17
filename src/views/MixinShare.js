export default {
  data() {
    return { record: null, shareTitlePrefix: "" };
  },
  onShareTimeline(options) {
    console.log(this.shareData)
    return this.shareData;
  },
  onShareAppMessage(options) {
    console.log(this.shareData)
    return this.shareData;
  },
  computed: {
    shareData() {
      console.log(this.record)
      return {
        title: this.shareTitlePrefix + (this.record?.title || ""),
        desc: this.record?.content.slice(0, 20) + "...",
        path: utils.getFullPath(),
        imageUrl: this.imageUrl
      };
    },
    imageUrl() {
      const img = this.record?.pics[0];
      return img ? (img.startsWith("http") ? img : "https:" + img) : "";
    }
  },
  methods: {}
};
