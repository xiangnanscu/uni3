<script setup>
const emit = defineEmits([
  "update:modelValue",
  "update:error",
  "blur:validate"
]);
const props = defineProps({
  field: { type: Object, required: true },
  modelValue: { required: true },
  error: {}
});
const uniFormItem = inject("uniFormItem", null);
const field = props.field;
const name = props.field.name;
const fieldType =
  props.field.type == "array" ? field.arrayType || "string" : props.field.type;
const getUniMediatype = (field) =>
  field.mediaType == "video"
    ? "video"
    : fieldType.includes("Image")
    ? "image"
    : "all";
const fileValues = ref({});
const filePickerRef = ref(null);
const autocompletePopupRef = ref(null);
// const uniFile = {
//   cloudPath: "1684568038130_0.png",
//   extname: "png",
//   fileType: "image",
//   image: {
//     width: 480,
//     height: 320,
//     location: "blob:http://localhost:5173/04cacb45-6257-4bbb-aa8a-3776cf839ef1"
//   },
//   name: "hx2.png",
//   path: "blob:http://localhost:5173/04cacb45-6257-4bbb-aa8a-3776cf839ef1",
//   progress: 0,
//   size: 7942,
//   status: "ready", // error|success|ready
//   url: "blob:http://localhost:5173/04cacb45-6257-4bbb-aa8a-3776cf839ef1",
//   uuid: 1684568038130
// };
const filePickerSelectHanlder = async ({ tempFiles, tempFilePaths }) => {
  console.log("filePickerSelectHanlder");
  const files = filePickerRef.value.files;
  for (const file of tempFiles) {
    const uniFileIndex = files.findIndex((f) => f.uuid == file.uuid);
    if (file.size > field.size) {
      emit(
        "update:error",
        `文件过大(当前${Math.round(file.size / 1024 / 1024)}MB,上限${
          field.sizeArg
        })`
      );
      files.splice(uniFileIndex, 1);
      continue;
    }
    try {
      const url = await Alioss.uploadUni({
        file,
        size: field.size,
        prefix: "img"
      });
      sendValue([...(props.modelValue || []), { ossUrl: url }]);
    } catch (error) {
      console.error(error);
      emit("update:error", error.message || "上传出错");
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
const sendValue = (value) => {
  emit("update:modelValue", value);
};
const blurValidate = () => {
  // uniFormItem.onFieldChange(props.modelValue);
  emit("blur:validate", props.modelValue);
  // if (props.error) emit("update:error", "");
  // try {
  //   sendValue(field.validate(props.modelValue));
  //   if (props.error) emit("update:error", "");
  // } catch (error) {
  //   console.error(error);
  //   emit("update:error", error.message);
  // }
};
</script>
<template>
  <template v-if="field.autocomplete">
    <uni-easyinput
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :placeholder="field.hint"
      @focus="autocompletePopupRef.open()"
      suffixIcon="forward"
    />
    <uni-popup ref="autocompletePopupRef" type="bottom" background-color="#fff">
      <uni-section :title="field.label" padding>
        <input
          @update:modelValue="sendValue"
          :modelValue="props.modelValue"
          :placeholder="field.hint"
          focus
        />
        <scroll-view :scroll-y="true" style="height: 31em">
          <uni-list>
            <uni-list-item
              v-for="(c, i) in props.modelValue
                ? field.choices.filter((e) =>
                    e.value.includes(props.modelValue)
                  )
                : []"
              clickable
              @click="
                sendValue(c.value);
                autocompletePopupRef.close();
              "
              :key="i"
              :title="c.value"
              :rightText="c.hint"
            />
          </uni-list>
        </scroll-view>
      </uni-section>
    </uni-popup>
  </template>
  <uni-easyinput
    v-else-if="fieldType == 'password'"
    type="password"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :disabled="field.disabled"
    :placeholder="field.hint"
  ></uni-easyinput>
  <template v-else-if="field.choices">
    <uni-data-checkbox
      v-if="field.tag == 'radio'"
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :localdata="field.choices"
      mode="tag"
    ></uni-data-checkbox>
    <uni-data-select
      v-else
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :localdata="field.choices"
    ></uni-data-select>
  </template>
  <slider
    v-else-if="field.tag == 'slider'"
    show-value
    @change="sendValue($event.detail.value)"
    :disabled="field.disabled"
    :value="props.modelValue"
    :min="field.min"
    :max="field.max"
  />
  <uni-datetime-picker
    v-else-if="fieldType == 'date'"
    type="date"
    :clear-icon="false"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :disabled="field.disabled"
    :placeholder="field.hint"
  />
  <uni-datetime-picker
    v-else-if="fieldType == 'datetime'"
    type="datetime"
    :clear-icon="false"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :disabled="field.disabled"
    :placeholder="field.hint"
  />
  <picker
    v-else-if="fieldType == 'yearMonth'"
    @change="sendValue($event.detail.value)"
    :value="props.modelValue"
    mode="date"
    fields="month"
  >
    <uni-easyinput
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :placeholder="field.hint"
      suffixIcon="forward"
    />
  </picker>
  <picker
    v-else-if="fieldType == 'year'"
    @change="sendValue($event.detail.value)"
    :value="props.modelValue"
    mode="date"
    fields="year"
  >
    <uni-easyinput
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :placeholder="field.hint"
      suffixIcon="forward"
    />
  </picker>
  <uni-file-picker
    v-else-if="fieldType.startsWith('alioss')"
    ref="filePickerRef"
    v-model="fileValues[name]"
    :file-mediatype="getUniMediatype(field)"
    :limit="fieldType.endsWith('List') ? field.limit || 9 : 1"
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
    v-else-if="fieldType == 'integer'"
    @blur="blurValidate"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :disabled="field.disabled"
    :placeholder="field.hint"
    type="number"
  />
  <uni-easyinput
    v-else-if="fieldType == 'float'"
    @blur="blurValidate"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :disabled="field.disabled"
    :placeholder="field.hint"
    type="digit"
  />
  <uni-easyinput
    v-else
    @blur="blurValidate"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
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
