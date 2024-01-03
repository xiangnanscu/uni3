<template>
  <view class="uni-list">
    <checkbox-group @change="checkboxChange">
      <template v-for="(item, i) in choices" :key="item.value">
        <label class="uni-list-cell">
          <checkbox
            :value="item.value"
            :checked="item.checked"
            :disabled="disableCheckBox(item.value, i)"
          />
          <div v-if="item.image">
            <image style="width: 75px; height: 75px" :src="item.image" mode="aspectFit" />
          </div>
          <view style="margin-right: 1em">{{ item.name }}</view>
        </label>
        <uni-easyinput
          v-if="lastOneEnter && i + 1 === choices.length && !enterInputHide"
          :disabled="disableCheckBox(item.value, i)"
          v-model.trim="enterValue"
          type="text"
        />
      </template>
    </checkbox-group>
  </view>
</template>

<script setup>
const props = defineProps({
  // focus: { type: Boolean, default: true },
  min: { type: Number },
  max: { type: Number },
  choices: { type: Array },
  modelValue: { type: Array },
});
const emit = defineEmits(["update:modelValue"]);
// 定义计算属性
const checkedNumber = computed(() => props.modelValue.length);
const enterInputHide = ref(true);
const enterValue = ref("");
watch(enterValue, (text) => {
  emit("update:modelValue", [...props.modelValue.slice(0, -1), text]);
});
const lastChoiceValue = computed(() => props.choices[props.choices.length - 1].value);
const lastOneEnter = computed(() => lastChoiceValue.value.slice(-2) === "其他");
const choicesValues = computed(() => props.choices.map((e) => e.value));

const disableCheckBox = (value, choiceIndex) => {
  if (checkedNumber.value >= props.max) {
    if (choiceIndex === props.choices.length - 1) {
      // 最后一个
      if (lastOneEnter.value) {
        // 达最大选择数, 最后一个, 有填空, 则仅当input值存在且输入值不包含input值的时候才禁用
        if (enterValue.value) {
          return !props.modelValue.includes(enterValue.value);
        } else {
          return !props.modelValue.includes(value);
        }
      } else {
        // 达最大选择数, 最后一个, 但没有填空
        return !props.modelValue.includes(value);
      }
    } else {
      // 达最大选择数, 但不是最后一个
      return !props.modelValue.includes(value);
    }
  } else {
    // 未达最大选择数
    return false;
  }
};
// 定义方法
function checkboxChange(e) {
  const values = e.detail.value;
  const lastValueInclude = values.includes(lastChoiceValue.value);
  utils.repr({ values, values2: props.modelValue });
  if (!lastOneEnter.value || !lastValueInclude) {
    emit("update:modelValue", values);
    enterInputHide.value = true;
  } else if (props.modelValue.length) {
    const lastModelValue = props.modelValue[props.modelValue.length - 1];
    const hasInputedText = !choicesValues.value.includes(lastModelValue);
    if (hasInputedText) {
      emit("update:modelValue", [...values.slice(0, -1), lastModelValue]);
    } else if (enterValue.value) {
      emit("update:modelValue", [...values.slice(0, -1), enterValue.value]);
    } else {
      emit("update:modelValue", values);
    }
    enterInputHide.value = false;
  } else {
    if (enterValue.value) {
      emit("update:modelValue", [...values.slice(0, -1), enterValue.value]);
    } else {
      emit("update:modelValue", values);
    }
    enterInputHide.value = false;
  }
  for (const item of props.choices) {
    item.checked = values.includes(item.value);
  }
}
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
