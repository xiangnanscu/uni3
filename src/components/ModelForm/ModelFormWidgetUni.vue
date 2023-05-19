<script setup>
import { useStore } from "@/store";

const emit = defineEmits(["update:modelValue"]);
const props = defineProps({
  name: { type: String, required: true },
  field: { type: Object, required: true },
  modelValue: { type: Object, required: true },
  values: { type: Object, default: () => ({}) }
});
const type = props.field.type;
const tag = field.tag;
</script>
<template>
  <template v-if="field.autocomplete"> </template>
  <template v-else> </template>
</template>
<style scoped>
.dynamic-delete-button {
  cursor: pointer;
  position: relative;
  top: 4px;
  font-size: 24px;
  color: #999;
  transition: all 0.3s;
}

.dynamic-delete-button:hover {
  color: red;
}
</style>
