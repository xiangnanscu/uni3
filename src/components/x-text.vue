<template>
  <div>
    <template v-for="(line, i) in props.text.split('\n')" :key="i">
      <div class="padding color" style="line-height: 200%">
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
  "indent",
  "color",
  "padding",
  "firstLineNoIndent",
]);
const textIndent = props.indent || "0";
const fontSize = props.size || "36rpx";
const padding = props.padding || "10rpx 5rpx";
const color = props.color || "black";
const lineHeight = props.lineHeight || "120%";
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
