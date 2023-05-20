<script setup>
const emit = defineEmits(["update:modelValue", "autocompleteFocus"]);
const props = defineProps({
  name: { type: String, required: true },
  field: { type: Object, required: true },
  modelValue: { type: Object, required: true },
  values: { type: Object, default: () => ({}) },
  errors: { type: Object, default: () => ({}) }
});
const ALIOSS_URL = process.env.ALIOSS_URL;
const type = props.field.type;
const tag = props.field.tag;
const name = props.field.name;
const values = props.values;
const errors = props.errors;
const getUniMediatype = (field) =>
  field.mediaType == "video"
    ? "video"
    : field.type.includes("Image")
    ? "image"
    : "all";
const fileValues = ref({});
const filePickerRef = ref(null);
const filePickerSelectHanlder = async ({ tempFiles, tempFilePaths }) => {
  const files = filePickerRef.files;
  for (const file of tempFiles) {
    const uniFileIndex = files.findIndex((f) => f.uuid == file.uuid);
    if (file.size > field.size) {
      errors[name] = `文件过大(当前${Math.round(
        file.size / 1024 / 1024
      )}MB,上限${field.sizeArg})`;
      files.splice(uniFileIndex, 1);
      continue;
    }
    try {
      const url = await Alioss.uploadUni({
        file,
        size: field.size,
        prefix: "img"
      });
      values[name].push({ ossUrl: url });
    } catch (error) {
      errors[name] = error.message || "上传出错";
      // files[uniFileIndex].errMsg = "上传出错";
      // files[uniFileIndex].status = "error";
      files.splice(uniFileIndex, 1);
    }
  }
};

// 以下三个都是uniCloud专用的
const filePickerFail = ({ tempFiles, tempFilePaths }) => {};
const filePickerSuccess = ({ tempFiles, tempFilePaths }) => {};
const filePickerProgress = ({
  progress,
  index,
  tempFile,
  tempFiles,
  tempFilePaths
}) => {};
</script>
<template>
  <uni-easyinput
    v-if="field.autocomplete"
    v-model="values[name]"
    :disabled="field.disabled"
    :placeholder="field.hint"
    @focus="emit('autocompleteFocus', name)"
    suffixIcon="forward"
  />
  <uni-easyinput
    v-else-if="field.type == 'password'"
    type="password"
    v-model="values[name]"
    :disabled="field.disabled"
    :placeholder="field.hint"
  ></uni-easyinput>
  <template v-else-if="field.choices">
    <uni-data-checkbox
      v-if="field.tag == 'radio'"
      :disabled="field.disabled"
      mode="tag"
      v-model="values[name]"
      :localdata="field.choices"
    ></uni-data-checkbox>
    <uni-data-select
      v-else
      :disabled="field.disabled"
      v-model="values[name]"
      :localdata="field.choices"
    ></uni-data-select>
  </template>
  <slider
    v-else-if="field.tag == 'slider'"
    show-value
    :disabled="field.disabled"
    @change="values[name] = $event.detail.value"
    :value="values[name]"
    :min="field.min"
    :max="field.max"
  />
  <uni-datetime-picker
    v-else-if="field.type == 'date'"
    type="date"
    :clear-icon="false"
    v-model="values[name]"
    :disabled="field.disabled"
    :placeholder="field.hint"
  />
  <uni-datetime-picker
    v-else-if="field.type == 'datetime'"
    type="datetime"
    :clear-icon="false"
    v-model="values[name]"
    :disabled="field.disabled"
    :placeholder="field.hint"
  />
  <picker
    v-else-if="field.type == 'yearMonth'"
    mode="date"
    fields="month"
    :value="values[name]"
    @change="values[name] = $event.detail.value"
  >
    <uni-easyinput
      v-model="values[name]"
      :disabled="field.disabled"
      :placeholder="field.hint"
      suffixIcon="forward"
    />
  </picker>
  <picker
    v-else-if="field.type == 'year'"
    mode="date"
    fields="year"
    :value="values[name]"
    @change="values[name] = $event.detail.value"
  >
    <uni-easyinput
      v-model="values[name]"
      :disabled="field.disabled"
      :placeholder="field.hint"
      suffixIcon="forward"
    />
  </picker>
  <uni-file-picker
    v-else-if="field.type.startsWith('alioss')"
    ref="filePickerRef"
    v-model="fileValues[name]"
    :file-mediatype="getUniMediatype(field)"
    :limit="field.type.endsWith('List') ? field.limit || 9 : 1"
    :disabled="field.disabled"
    :title="' '"
    mode="grid"
    :disable-preview="true"
    return-type="array"
    @select="filePickerSelectHanlder"
    @success="filePickerSuccess"
    @progress="filePickerProgress"
    @fail="filePickerFail"
  />
  <uni-easyinput
    v-else-if="field.type == 'integer'"
    v-model="values[name]"
    :disabled="field.disabled"
    :placeholder="field.hint"
    type="number"
  />
  <uni-easyinput
    v-else-if="field.type == 'float'"
    v-model="values[name]"
    :disabled="field.disabled"
    :placeholder="field.hint"
    type="digit"
  />
  <uni-easyinput
    v-else
    v-model="values[name]"
    :disabled="field.disabled"
    :placeholder="field.hint"
  />
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
