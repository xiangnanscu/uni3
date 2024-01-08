<template>
  <view class="uni-list">
    <radio-group @change="radioChange">
      <label class="uni-list-cell" v-for="(item, i) in choices" :key="item.value">
        <radio :value="item.value" :checked="item.checked" />
        <div v-if="item.image">
          <image style="width: 75px; height: 75px" :src="item.image" mode="aspectFit" />
        </div>
        <view style="margin-right: 1em">{{ item.name }}</view>
        <uni-easyinput
          v-if="lastOneEnter && i + 1 === choices.length && !enterInputHide"
          v-model.trim="enterValue"
          type="text"
        />
      </label>
    </radio-group>
  </view>
</template>

<script setup>
const props = defineProps({
  choices: { type: Array },
  modelValue: {},
});
const emit = defineEmits(["update:modelValue"]);
const enterValue = ref();
const enterInputHide = ref(true);
watch(enterValue, (text) => {
  emit("update:modelValue", text);
});

const lastChoiceValue = computed(() => props.choices[props.choices.length - 1].value);
const lastOneEnter = computed(() => lastChoiceValue.value.slice(-2) === "其他");
const radioChange = function (e) {
  const choice = e.detail.value;
  if (!lastOneEnter.value || choice !== lastChoiceValue.value) {
    emit("update:modelValue", choice);
    enterInputHide.value = true;
  } else {
    emit("update:modelValue", "");
    enterInputHide.value = false;
  }

  for (const item of props.choices) {
    item.checked = item === choice;
  }
};
</script>

<style scoped>
.uni-list-cell {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
  margin-bottom: 1em;
}
</style>
