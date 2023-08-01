<template>
  <div>
    <rich-text :nodes="miniHtml" @itemclick="itemclick"></rich-text>
  </div>
</template>

<script>
const classTagNames = [
  "img",
  "p",
  "span",
  "a",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6"
];
export default {
  props: {
    html: { type: String }
  },
  data() {
    return {};
  },
  computed: {
    miniHtml() {
      let res = this.html;
      // res = res.replaceAll(/<img/g, '<img click="foo"');
      for (const tag of classTagNames) {
        res = res.replaceAll(
          new RegExp(`<${tag}`, "g"),
          `<${tag} class="tinymce-${tag}"`
        );
      }
      // console.log(res);
      return res;
    }
  },
  methods: {
    itemclick(e) {
      console.log("itemclick", e);
      if (e.detail?.node?.name == "img") {
        uni.previewImage({
          urls: [e.detail.node.attrs.src],
          current: 0
        });
      }
    }
  }
};
</script>

<style scoped>
:deep(.tinymce-img) {
  width: 100%;
  height: auto;
}
:deep(.tinymce-p) {
  color: black;
  margin-bottom: 1em;
  font-size: 12pt;
  line-height: 1.3;
}

:deep(.tinymce-h1),
:deep(.tinymce-h2),
:deep(.tinymce-h3),
:deep(.tinymce-h4),
:deep(.tinymce-h5),
:deep(.tinymce-h6) {
  color: black;
  margin-bottom: 1em;
}
</style>
