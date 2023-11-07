<template>
  <div>
    <div v-for="(line, i) in props.text.split('\n')" :key="i">
      <fui-text
        v-if="line.trim()"
        class="p"
        :padding="['5px', '5px']"
        :selectable="true"
        :text="line"
        :size="props.size || 36"
      ></fui-text>
    </div>
  </div>
</template>

<script setup>
const props = defineProps(["text", "size", "textIndent"]);
const textIndent = props.textIndent || "0";
</script>

<style scoped>
.p {
  text-indent: v-bind(textIndent);
}
</style>
