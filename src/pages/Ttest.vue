<template>
  <div
    text="BUG"
    @select-files="
      ({ files }) => {
        for (const file of files) {
          log('aa', file?.name);
        }
      }
    "
  />
  <inline-test text="OK" @select-files="selectFiles" />
</template>
<script setup>
const log = console.log;
const selectFiles = ({ files }) => {
  for (const file of files) {
    console.log("aa", file?.name);
  }
};
</script>
