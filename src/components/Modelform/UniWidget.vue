<script setup>
const emit = defineEmits(["update:modelValue", "update:error", "blur:validate"]);
const props = defineProps({
  field: { type: Object, required: true },
  modelValue: { required: true },
  error: { type: String, default: "" },
});
// const uniFormItem = inject("uniFormItem", null);
const field = props.field;
const fieldType = props.field.type;
const mediaType =
  field.media_type == "video" ? "video" : fieldType.includes("image") ? "image" : "all";
const filePickerRef = ref(null);
const autocompletePopupRef = ref(null);
const searchText = ref("");
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
const sendValue = (value) => {
  emit("update:modelValue", value);
};
const fileLimit = fieldType.endsWith("_list") ? field.limit || 9 : 1;
const filePickerSelectHanlder = async ({ tempFiles, tempFilePaths }) => {
  emit("update:error", "");
  const files = filePickerRef.value.files;
  for (const file of tempFiles) {
    const uniFileIndex = files.findIndex((f) => f.uuid == file.uuid);
    if (file.size > field.size) {
      emit(
        "update:error",
        `文件过大(当前${Math.round(file.size / 1024 / 1024)}MB,上限${field.size_arg})`,
      );
      files.splice(uniFileIndex, 1);
      continue;
    }
    try {
      const url = await Alioss.uploadUni({
        file,
        size: field.size,
        prefix: "img",
      });
      const fileObj = { ...file, ossUrl: url, url };
      if (fileLimit === 1) {
        sendValue([fileObj]);
      } else {
        sendValue([...(props.modelValue || []), fileObj]);
      }
    } catch (error) {
      console.error(error);
      emit("update:error", error.message || "上传出错");
      files.splice(uniFileIndex, 1);
    }
  }
};
const filePickerDelete = ({ tempFile, tempFiles }) => {
  const index = props.modelValue.findIndex((file) => file.uuid === tempFile.uuid);
  if (index !== -1)
    sendValue([
      ...props.modelValue.slice(0, index),
      ...props.modelValue.slice(index + 1),
    ]);
};
// 以下三个都是uniCloud专用的
const filePickerFail = ({ tempFiles, tempFilePaths }) => {};
const filePickerSuccess = ({ tempFiles, tempFilePaths }) => {};
const filePickerProgress = ({
  progress,
  index,
  tempFile,
  tempFiles,
  tempFilePaths,
}) => {};
const blurValidate = () => {
  emit("update:error", ""); // 先清除老错误
  emit("blur:validate", props.modelValue);
};
const isArrayField = computed(() => field.type == "array");
const easyInputTypeMap = {
  integer: "number",
  float: "digit",
  password: "password",
  nickname: "nickname",
  textarea: "textarea",
  text: "textarea",
};
const easyType = computed(
  () => easyInputTypeMap[field.type] || easyInputTypeMap[field.input_type],
);
const getPhoneNumber = async (event) => {
  // 用户允许: e.detail = {errMsg: "getPhoneNumber:ok", code: "??", encryptedData: "??", iv: "??"}
  // 用户拒绝: e.detail = {errMsg: "getPhoneNumber:fail user deny"}
  const { code } = event.detail;
  if (code) {
    const { data } = await Http.post("/wx_phone", { code });
    sendValue(data.purePhoneNumber);
  }
};
let wxPhoneDisabled = field.disabled === undefined ? false : field.disabled;
// #ifdef H5
wxPhoneDisabled = false;
field.attrs.wxPhone = false;
field.attrs.wx_avatar = false;
// #endif
const placeholder = field.attrs?.placeholder || field.hint;
const fuiSelectShow = ref();
const onFuiSelectConfirm = ({ index, options }) => {
  if (index === -1) {
    return;
  }
  sendValue(options.value);
  fuiSelectShow.value = false;
};
let fieldChoices, fuiChoices;
onLoad(async () => {
  if (typeof field.choices == "function") {
    field.choices = await field.choices();
    if (field.type == "foreignkey") {
      field.prepare_choices();
    }
  }
  if (Array.isArray(field.choices)) {
    fieldChoices = field.choices.map((e) => ({
      _value: e._value,
      text: e.label,
      value: e.value,
    }));
    fuiChoices = field.choices.map((e) => ({
      _value: e._value,
      text: e.label,
      value: e.value,
      checked: e.value === props.modelValue,
    }));
  }
});
const showChoicesWhenSmall = (field) => {
  if (
    field.choices.length <
    (field.max_display_count || Number(process.env.MAX_DISPLAY_COUNT) || 20)
  ) {
    return fieldChoices.slice();
  } else {
    return [];
  }
};
</script>
<template>
  <template v-if="field.autocomplete">
    <uni-easyinput
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :placeholder="placeholder"
      @focus="autocompletePopupRef.open()"
      suffixIcon="forward"
    />
    <uni-popup ref="autocompletePopupRef" type="bottom" background-color="#fff">
      <div style="padding: 1em">
        <div style="text-align: center; margin-bottom: 1em">
          {{ field.label }}
        </div>
        <input v-model="searchText" :placeholder="field.hint || '输入关键字查找'" focus />
        <scroll-view :scroll-y="true" style="height: 31em">
          <uni-list>
            <uni-list-item
              v-for="(c, i) in searchText
                ? fieldChoices.filter((e) => {
                    if (typeof e.text == 'string') {
                      return e.text.includes(searchText);
                    } else {
                      return true;
                    }
                  })
                : showChoicesWhenSmall(field)"
              clickable
              @click="
                sendValue(c.value);
                if (field.type == 'foreignkey' && Array.isArray(field.choices)) {
                  const matched = field.choices.find((e) => e.value === c.value);
                  if (matched) {
                    field._postValue = matched._value;
                  } else {
                    field._postValue = null;
                  }
                }
                autocompletePopupRef.close();
              "
              :key="i"
              :title="c.text"
              :rightText="c.hint"
            />
          </uni-list>
        </scroll-view>
      </div>
    </uni-popup>
  </template>
  <template v-else-if="fieldChoices">
    <uni-data-checkbox
      v-if="isArrayField || field.tag == 'radio'"
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :localdata="fieldChoices"
      :multiple="isArrayField ? true : false"
      :max="isArrayField ? field.max || Infinity : 1"
      :min="field.min || 0"
      :mode="isArrayField ? 'list' : 'tag'"
    ></uni-data-checkbox>
    <div v-else-if="field.attrs.fui">
      <div style="display: flex; align-items: center">
        <div
          style="text-align: center; width: 100%; font-size2: 120%; font-weight2: bold"
        >
          {{ props.modelValue }}
        </div>
        <div style="width: 100%">
          <x-button size="mini" @click="fuiSelectShow = true">点击选择</x-button>
        </div>
      </div>
      <fui-select
        :show="fuiSelectShow"
        :options="fuiChoices"
        :multiple="isArrayField"
        checkboxColor2="#FFC529"
        btnBackground2="#FFC529"
        btnColor2="#1A1D26"
        closeColor="#6D758A"
        @close="fuiSelectShow = false"
        @confirm="onFuiSelectConfirm"
      ></fui-select>
    </div>
    <uni-data-select
      v-else
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :localdata="fieldChoices"
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
    :placeholder="placeholder"
  />
  <uni-datetime-picker
    v-else-if="fieldType == 'datetime'"
    type="datetime"
    :clear-icon="false"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :disabled="field.disabled"
    :placeholder="placeholder"
  />
  <picker
    v-else-if="fieldType == 'year_month'"
    @change="sendValue($event.detail.value)"
    :value="props.modelValue"
    mode="date"
    fields="month"
  >
    <uni-easyinput
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :placeholder="placeholder"
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
      :placeholder="placeholder"
      suffixIcon="forward"
    />
  </picker>
  <template v-else-if="fieldType.startsWith('alioss')">
    <wx-avatar
      v-if="field.attrs.wx_avatar"
      @update:modelValue="sendValue"
      @update:error="emit('update:error', $event)"
      :modelValue="{ url: props.modelValue, errMsg: props.error }"
      :size="field.size_arg"
    ></wx-avatar>
    <uni-file-picker
      v-else
      ref="filePickerRef"
      :del-icon="true"
      :modelValue="props.modelValue"
      @update:modelValue="sendValue"
      :file-mediatype="mediaType"
      :limit="fileLimit"
      :disabled="field.disabled"
      :title="' '"
      mode="grid"
      :disable-preview="true"
      :image-styles="field.attrs.image_styles"
      return-type="array"
      @select="filePickerSelectHanlder"
      @success="filePickerSuccess"
      @progress="filePickerProgress"
      @fail="filePickerFail"
      @delete="filePickerDelete"
    />
    <div v-if="field.hint" class="field-hint" :style="field.attrs.hint_styles">
      {{ field.hint }}
    </div>
  </template>
  <template v-else-if="field.attrs.wxPhone">
    <uni-easyinput
      @blur="blurValidate"
      @update:modelValue="sendValue"
      :error-message="props.error"
      disable-color="black"
      :modelValue="props.modelValue"
      :disabled="wxPhoneDisabled"
      :placeholder="placeholder"
    />
    <button
      type="primary"
      :plain="true"
      size="mini"
      open-type="getPhoneNumber"
      @getphonenumber="getPhoneNumber"
    >
      获取微信手机号
    </button>
  </template>
  <uni-easyinput
    v-else
    @blur="blurValidate"
    @update:modelValue="sendValue"
    :error-message="props.error"
    :modelValue="props.modelValue"
    :disabled="field.disabled"
    :placeholder="placeholder"
    :type="easyType || 'text'"
  />
</template>
<style scoped>
.field-hint {
  padding: 4px 0;
}
</style>
