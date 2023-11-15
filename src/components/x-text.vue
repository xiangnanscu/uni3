<template>
  <div>
    <template v-for="(line, i) in props.text.split('\n')" :key="i">
      <div class="padding color">
        <text
          v-if="line.trim()"
          :class="{ indent: firstLineNoIndent ? i > 0 : true, size: true }"
          :selectable="true"
          :userSelect="true"
          >{{ line }}</text
        >
      </div>
    </template>
  </div>
</template>

<script setup>
const props = defineProps([
  "text",
  "size",
  "textIndent",
  "color",
  "padding",
  "firstLineNoIndent",
]);
const textIndent = props.textIndent || "0";
const fontSize = props.fontSize || "36rpx";
const padding = props.padding || "5rpx";
const color = props.color || "black";
const firstLineNoIndent = props.firstLineNoIndent;
</script>

<style scoped>
.indent {
  text-indent: v-bind(textIndent);
}
.size {
  font-size: v-bind(fontSize);
}
.padding {
  padding: v-bind(padding);
}
.color {
  color: v-bind(color);
}
</style>
