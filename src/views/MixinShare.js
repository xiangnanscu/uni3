export default {
  data() {
    return { record: null };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
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
        title: this.record?.title,
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
