<template>
  <div>
    <rich-text :nodes="miniHtml"></rich-text>
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
    change() {}
  }
};
</script>

<style scoped>
:deep(.tinymce-img) {
  width: 100%;
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
