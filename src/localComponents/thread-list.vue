<template>
  <uni-list :border="false" v-if="records.length">
    <uni-list-item
      v-for="(e, index) in records"
      :key="index"
      :to="`/views/ThreadDetail?id=${e.id}`"
      :avatar="e.creator.avatar"
      :thumb="e.creator.avatar"
      thumb-size="lg"
      :right-text="utils.fromNow(e.ctime)"
      :title="e.title"
      :note="e.creator.nickname"
      :avatar-circle="true"
    ></uni-list-item>
  </uni-list>
  <f-alert v-else>还没有帖子, 快来首发吧! </f-alert>
</template>

<script>
export default {
  props: {
    records: { type: Array, default: () => [] },
  },
};
</script>

<style scoped></style>
