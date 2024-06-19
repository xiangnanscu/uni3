<template>
  <uni-tag
    style="cursor: pointer"
    :text="props.text"
    :type="props.type"
    @click="emit('click')"
    :disabled="store.loading"
  ></uni-tag>
</template>

<script setup>
const emit = defineEmits(["click"]);
const props = defineProps({
  type: { type: String, default: "default" },
  text: { type: String },
});
const store = useStore();
</script>
<style scoped></style>
