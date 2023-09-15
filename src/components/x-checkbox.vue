<template>
  <view class="uni-list">
    <checkbox-group @change="checkboxChange">
      <label class="uni-list-cell" v-for="item in choices" :key="item.value">
        <checkbox
          :value="item.value"
          :checked="item.checked"
          :disabled="checkedNumber >= max && !modelValue.includes(item.value)"
        />
        <div v-if="item.image">
          <image
            style="width: 75px; height: 75px"
            :src="item.image"
            mode="aspectFit"
          />
        </div>
        <view>{{ item.name }}</view>
      </label>
    </checkbox-group>
  </view>
</template>

<script setup>
const props = defineProps({
  // focus: { type: Boolean, default: true },
  min: { type: Number },
  max: { type: Number },
  choices: { type: Array },
  modelValue: { type: Array }
});
const emit = defineEmits(["update:modelValue"]);
const p = (e) => console.log(e);
</script>

<script>
export default {
  data() {
    return {};
  },
  computed: {
    checkedNumber() {
      return this.modelValue.length;
    }
  },
  methods: {
    checkboxChange: function (e) {
      const values = e.detail.value;
      this.$emit("update:modelValue", values);
      for (const item of this.choices) {
        item.checked = values.includes(item.value);
      }
    }
  }
};
</script>

<style scoped>
.uni-list-cell {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
}
</style>
