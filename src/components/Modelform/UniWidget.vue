<script setup>
// const uniFile = {
//   cloudPath: "1684568038130_0.png",
//   extname: "png",
//   fileType: "image",
//   image: {
//     width: 480,
//     height: 320,
//     location: "blob:http://localhost:5183/04cacb45-6257-4bbb-aa8a-3776cf839ef1"
//   },
//   name: "hx2.png",
//   path: "blob:http://localhost:5183/04cacb45-6257-4bbb-aa8a-3776cf839ef1",
//   progress: 0,
//   size: 7942,
//   status: "ready", // error|success|ready
//   url: "blob:http://localhost:5183/04cacb45-6257-4bbb-aa8a-3776cf839ef1",
//   uuid: 1684568038130
// };
const emit = defineEmits(["update:modelValue", "update:error", "blur:validate", "update:values"]);
const props = defineProps({
  field: { type: Object, required: true },
  modelValue: { required: true },
  error: { type: String, default: "" },
  borderColor: { type: String, default: "#ccc" },
});
// const uniFormItem = inject("uniFormItem", null);
const ready = ref(); //确保一些需要提前异步获取到数据加载完之后再渲染
const fieldType = computed(() => props.field.type);
const mediaType = props.field.media_type == "video" ? "video" : fieldType.value.includes("image") ? "image" : "all";
const filePickerRef = ref(null);
const autocompletePopupRef = ref(null);
const autocompleteSearchText = ref("");
const autocompleteInputValue = ref("");
const sendValue = (value) => {
  emit("update:modelValue", value);
};
const sendError = (value) => {
  emit("update:error", value);
};
const blurValidate = () => {
  emit("update:error", ""); // 先清除老错误
  emit("blur:validate", props.modelValue);
};
const fileLimit = fieldType.value.endsWith("_list") ? props.field.limit || 9 : 1;
const filePickerSelectHanlder = async ({ tempFiles, tempFilePaths }) => {
  emit("update:error", "");
  const files = filePickerRef.value.files;
  for (const file of tempFiles) {
    const uniFileIndex = files.findIndex((f) => f.uuid == file.uuid);
    if (file.size > props.field.size) {
      emit("update:error", `文件过大(当前${Math.round(file.size / 1024 / 1024)}MB,上限${props.field.size_arg})`);
      files.splice(uniFileIndex, 1);
      continue;
    }
    try {
      const url = await Alioss.uploadUni({
        file,
        size: props.field.size,
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
  if (index !== -1) sendValue([...props.modelValue.slice(0, index), ...props.modelValue.slice(index + 1)]);
};
// 以下三个都是uniCloud专用的
const filePickerFail = ({ tempFiles, tempFilePaths }) => {};
const filePickerSuccess = ({ tempFiles, tempFilePaths }) => {};
const filePickerProgress = ({ progress, index, tempFile, tempFiles, tempFilePaths }) => {};

const isArrayField = computed(() => props.field.type == "array");
const easyInputTypeMap = {
  integer: "number",
  float: "digit",
  password: "password",
  nickname: "nickname",
  textarea: "textarea",
  text: "textarea",
};
const easyType = computed(() => easyInputTypeMap[props.field.type] || easyInputTypeMap[props.field.input_type]);
const getPhoneNumber = async (event) => {
  // 用户允许: e.detail = {errMsg: "getPhoneNumber:ok", code: "??", encryptedData: "??", iv: "??"}
  // 用户拒绝: e.detail = {errMsg: "getPhoneNumber:fail user deny"}
  const { code } = event.detail;
  if (code) {
    const { data } = await Http.post("/wx_phone", { code });
    sendValue(data.purePhoneNumber);
  }
};
const placeholder = computed(() => props.field.attrs?.placeholder || props.field.hint);
const showSelect = ref();
const pickerCurrentChoice = computed(() => {
  const lastGroup = props.field.group[props.field.group.length - 1];
  const key = lastGroup.value_key;
  return props.field.choices.find((c) => c[key] === props.modelValue);
});
const pickerResultText = computed(() => {
  if (props.field.group) {
    const c = pickerCurrentChoice.value;
    return c ? props.field.group.map((opts) => `${c[opts.label_key]}`).join("") : "";
  } else {
    return fieldChoices.value.find((c) => c.value === props.modelValue)?.text;
  }
});
const pickerInitValue = computed(() => {
  if (props.modelValue == null) {
    return [];
  } else if (props.field.group) {
    return props.field.group.map((opts) => pickerCurrentChoice.value?.[opts.label_key]);
  } else {
    return props.modelValue;
  }
});
const onPickerConfirm = (e) => {
  // console.log(e);
  if (props.field.group) {
    for (const [i, opts] of props.field.group.entries()) {
      emit("update:values", { [opts.form_key || opts.value_key]: e.value[i] });
    }
  } else {
    sendValue(e.value);
  }
  sendError("");
  showSelect.value = false;
};
const fieldChoices = computed(() => {
  if (!Array.isArray(props.field.choices)) {
    return null;
  }
  const group = props.field.group;
  if (group) {
    const choices = [];
    for (const c of props.field.choices) {
      let currentLevel = choices;
      for (const [i, opts] of group.entries()) {
        let l = currentLevel.find((e) => e.value == c[opts.value_key]);
        if (!l) {
          l = { value: c[opts.value_key], text: c[opts.label_key] };
          if (i < group.length - 1) {
            l.children = [];
          }
          currentLevel.push(l);
        }
        currentLevel = l.children;
      }
    }
    return choices;
  } else if (fieldType.value === "array") {
    return props.field.field.choices.map((e) => ({
      ...e, // 保留其他属性
      text: e.label,
      value: e.value,
    }));
  } else {
    return props.field.choices.map((e) => ({
      ...e, // 保留其他属性
      text: e.label,
      value: e.value,
    }));
  }
});
const showChoicesWhenSmall = (field) => {
  // console.log("showChoicesWhenSmall call");
  if (field.choices.length < (field.max_display_count || Number(process.env.MAX_DISPLAY_COUNT) || 20)) {
    return fieldChoices.value.slice();
  } else {
    return [];
  }
};
</script>
<template>
  <template v-if="fieldChoices">
    <template v-if="props.field.group">
      <fui-list-cell arrow @click="showSelect = true" :padding="[0]" :bottomBorder="false" borderColor="transparent">
        {{ pickerResultText }}
        <view class="fui-list-input" :style="{ 'background-color': borderColor }"> </view>
      </fui-list-cell>
      <fui-picker
        linkage
        :value="pickerInitValue"
        :options="fieldChoices"
        :layer="props.field.group?.length || 1"
        :show="showSelect"
        @change="onPickerConfirm"
        @cancel="showSelect = false"
      ></fui-picker>
    </template>
    <template v-else-if="props.field.autocomplete">
      <uni-easyinput
        v-model="autocompleteInputValue"
        :disabled="props.field.disabled"
        :placeholder="placeholder"
        @focus="autocompletePopupRef.open()"
        suffixIcon="forward"
      />
      <uni-popup ref="autocompletePopupRef" type="bottom" background-color="#fff">
        <div style="padding: 1em">
          <div style="text-align: center; margin-bottom: 1em">
            {{ props.field.label }}
          </div>
          <uni-easyinput v-model="autocompleteSearchText" :placeholder="props.field.hint || '输入关键字查找'" focus />
          <scroll-view :scroll-y="true" style="height: 31em">
            <uni-list>
              <uni-list-item
                v-for="(c, i) in autocompleteSearchText
                  ? fieldChoices.filter((e) => {
                      if (typeof e.text == 'string') {
                        return e.text.includes(autocompleteSearchText);
                      } else {
                        return true;
                      }
                    })
                  : showChoicesWhenSmall(props.field)"
                clickable
                @click="
                  sendValue(c.value);
                  autocompleteInputValue = c.label;
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
    <uni-data-checkbox
      v-else-if="isArrayField || props.field.tag == 'radio'"
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="props.field.disabled"
      :localdata="fieldChoices"
      :multiple="isArrayField ? true : false"
      :max="isArrayField ? props.field.max || Infinity : 1"
      :min="props.field.min || 0"
      :mode="isArrayField ? 'list' : 'tag'"
    ></uni-data-checkbox>
    <template v-else>
      <fui-list-cell arrow @click="showSelect = true" :padding="[0]" :bottomBorder="false" borderColor="transparent">
        {{ pickerResultText }}
        <view class="fui-list-input" :style="{ 'background-color': borderColor }"> </view>
      </fui-list-cell>
      <fui-picker
        linkage
        :value="pickerInitValue"
        :options="fieldChoices"
        :layer="1"
        :show="showSelect"
        @change="onPickerConfirm"
        @cancel="showSelect = false"
      ></fui-picker>
    </template>
  </template>
  <slider
    v-else-if="props.field.tag == 'slider'"
    show-value
    @change="sendValue($event.detail.value)"
    :disabled="props.field.disabled"
    :value="props.modelValue"
    :min="props.field.min"
    :max="props.field.max"
  />
  <uni-datetime-picker
    v-else-if="fieldType == 'date'"
    type="date"
    :clear-icon="false"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :disabled="props.field.disabled"
    :placeholder="placeholder"
  />
  <uni-datetime-picker
    v-else-if="fieldType == 'datetime'"
    type="datetime"
    :clear-icon="false"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :disabled="props.field.disabled"
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
      :disabled="props.field.disabled"
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
      :disabled="props.field.disabled"
      :placeholder="placeholder"
      suffixIcon="forward"
    />
  </picker>
  <template v-else-if="fieldType.startsWith('alioss')">
    <wx-avatar
      v-if="props.field.attrs.wx_avatar"
      @update:modelValue="sendValue"
      @update:error="emit('update:error', $event)"
      :modelValue="{ url: props.modelValue, errMsg: props.error }"
      :size="props.field.size_arg"
    ></wx-avatar>
    <uni-file-picker
      v-else
      ref="filePickerRef"
      :del-icon="true"
      :modelValue="props.modelValue"
      @update:modelValue="sendValue"
      :file-mediatype="mediaType"
      :limit="fileLimit"
      :disabled="props.field.disabled"
      :title="' '"
      mode="grid"
      :disable-preview="true"
      :image-styles="props.field.attrs.image_styles"
      return-type="array"
      @select="filePickerSelectHanlder"
      @success="filePickerSuccess"
      @progress="filePickerProgress"
      @fail="filePickerFail"
      @delete="filePickerDelete"
    />
    <div v-if="props.field.hint" class="field-hint" :style="props.field.attrs.hint_style">
      {{ props.field.hint }}
    </div>
  </template>
  <template v-else-if="props.field.attrs.wx_phone">
    <uni-easyinput
      @blur="blurValidate"
      @update:modelValue="sendValue"
      :error-message="props.error"
      disable-color="black"
      :modelValue="props.modelValue"
      :disabled="props.field.disabled"
      :placeholder="placeholder"
    />
    <x-button
      type="primary"
      :plain="true"
      text="获取微信手机号"
      size="mini"
      open-type="getPhoneNumber"
      @getphonenumber="getPhoneNumber"
    >
      获取微信手机号
    </x-button>
  </template>
  <uni-easyinput
    v-else
    @blur="blurValidate"
    @update:modelValue="sendValue"
    :error-message="props.error"
    :modelValue="props.modelValue"
    :disabled="props.field.disabled"
    :placeholder="placeholder"
    :type="easyType || 'text'"
  />
</template>

<style scoped>
.fui-list-input {
  position: absolute;
  bottom: 0;
  height: 1px;
  transform: scaleY(0.5) translateZ(0);
  transform-origin: 0 100%;
  z-index: 1;
  background-color: v-bind(borderColor);
  width: 100%;
}
.field-hint {
  padding: 4px 0;
}
</style>
