<template>
  <view class="uni-list">
    <checkbox-group @change="checkboxChange">
      <label
        class="uni-list-cell uni-list-cell-pd"
        v-for="item in choices"
        :key="item.value"
      >
        <checkbox :value="item.value" :checked="item.checked" />
        <div v-if="item.image" style="width: 20px; height: 20px">
          <image :src="item.image" mode="f" />
        </div>

        <view>{{ item.name }}</view>
      </label>
    </checkbox-group>
  </view>
</template>

<script setup>
const props = defineProps({
  // focus: { type: Boolean, default: true },
  choices: { type: Array },
  modelValue: { type: Array }
});
console.log(props.choices);
const emit = defineEmits(["update:modelValue"]);
</script>

<script>
export default {
  data() {
    return {};
  },
  methods: {
    checkboxChange: function (e) {
      const items = this.choices,
        values = e.detail.value;
      this.$emit("update:modelValue", values);
      for (var i = 0, lenI = items.length; i < lenI; ++i) {
        const item = items[i];
        if (values.includes(item.value)) {
          this.$set(item, "checked", true);
        } else {
          this.$set(item, "checked", false);
        }
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
}
</style>
