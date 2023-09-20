<template>
  <view class="uni-list">
    <radio-group @change="radioChange">
      <label class="uni-list-cell" v-for="item in choices" :key="item.value">
        <radio :value="item.value" :checked="item.checked" />
        <div v-if="item.image">
          <image
            style="width: 75px; height: 75px"
            :src="item.image"
            mode="aspectFit"
          />
        </div>
        <view>{{ item.name }}</view>
      </label>
    </radio-group>
  </view>
</template>

<script setup>
const props = defineProps({
  choices: { type: Array },
  modelValue: {}
});
const emit = defineEmits(["update:modelValue"]);
</script>

<script>
export default {
  data() {
    return {};
  },
  computed: {},
  methods: {
    radioChange: function (e) {
      const choice = e.detail.value;
      this.$emit("update:modelValue", choice);
      for (const item of this.choices) {
        item.checked = item === choice;
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
