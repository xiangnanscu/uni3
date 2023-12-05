<script setup>
const emit = defineEmits([
  "update:modelValue",
  "update:error",
  "blur:validate",
  "update:values",
]);
const props = defineProps({
  field: { type: Object, required: true },
  modelValue: { required: true },
  error: { type: String, default: "" },
  borderColor: { type: String, default: "#ccc" },
});
// const uniFormItem = inject("uniFormItem", null);
const fieldType = computed(() => props.field.type);
const isArrayField = computed(() => fieldType.value === "array");
const sendValue = (value) => {
  emit("update:modelValue", value);
};
const sendError = (value) => {
  emit("update:error", value);
};
const blurValidate = (event) => {
  sendError("");
  emit("blur:validate", event);
};

const easyInputTypeMap = {
  integer: "number",
  float: "digit",
  password: "password",
  nickname: "nickname",
  textarea: "textarea",
  text: "textarea",
};
const easyType = computed(
  () => easyInputTypeMap[props.field.type] || easyInputTypeMap[props.field.input_type],
);
const getPhoneNumber = async (event) => {
  // fui-button接口不一样, 不用event.detail
  // 用户允许: e = {errMsg: "getPhoneNumber:ok", code: "??", encryptedData: "??", iv: "??"}
  // 用户拒绝: e = {errMsg: "getPhoneNumber:fail user deny"}
  console.log("getPhoneNumber", event);
  const { code } = event;
  if (code) {
    const { data } = await Http.post("/wx_phone", { code });
    sendValue(data.purePhoneNumber);
    sendError("");
  }
};
const placeholder = computed(() => props.field.attrs?.placeholder || props.field.hint);
const fieldInline = computed(() => !!props.field.attrs.inline);
const showArrow = computed(() => props.field.choices && props.field.tag == "select");
const formItemEvents = {};
const showSelect = ref();
const onSelectClick = ({ index, options }) => {
  sendValue(options.value);
  sendError("");
  showSelect.value = false;
};
const onSelectConfirm = ({ index, options }) => {
  // log("onSelectConfirm", { index, options });
  sendValue(options.value);
  sendError("");
  showSelect.value = false;
};
const pickerResultText = ref();
const onPickerConfirm = (e) => {
  // log(e);
  pickerResultText.value = e.result;
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
if (showArrow) {
  formItemEvents.click = (e) => {
    showSelect.value = true;
  };
}
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
const fuiChoices = computed(() =>
  fieldChoices.value.map((e) => ({
    ...e,
    checked: e.value === props.modelValue,
  })),
);
const fuiUploader = ref();
const fuiUploadStatus = ref();
const fileLimit = computed(() =>
  fieldType.value.endsWith("_list") ? props.field.limit || 9 : 1,
);
const fuiUploadComplete = async (e) => {
  console.log("fuiUploadComplete", e);
  if (e.action == "choose" && e.status == "preupload") {
    await fuiCallUpload();
  } else if (e.action == "upload") {
    fuiUploadStatus.value = e.status;
    if (e.status === "success") {
      uni.showToast({ title: "上传完成！" });
    }
  } else if (e.action === "delete") {
    console.log("delete", e.urls.length);
    sendValue([...e.urls]);
  }
};
const fuiDeleteFile = (file) => {
  // 用于在上传到OSS之前强行删除本地文件
  const index = fuiUploader.value.tempFiles.findIndex((f) => f.path === file.path);
  if (index !== -1) {
    fuiUploader.value.urls.splice(index, 1);
    fuiUploader.value.tempFiles.splice(index, 1);
    fuiUploader.value.status.splice(index, 1);
  }
};
const compressJPG = async (file) => {
  // log("before compress", await uni.getImageInfo({ src: file.path }));
  const cfile = await uni.compressImage({
    src: file.path,
    quality: props.field.attrs.compress_quality || 10,
  });
  // log({ cfile });
  // log(file.path);
  // log("after compress", await uni.getImageInfo({ src: cfile.tempFilePath }));
  return cfile.tempFilePath;
};
const fuiUploadCallback = async (file) => {
  // log("fuiUploadCallback", file);
  //上传的文件信息
  try {
    // #ifdef MP-WEIXIN
    // 微信平台file对象只有path和size属性
    const [_, name, ext] = file.path.match(/\/(\w+)\.(\w+)$/);
    file.name = `${name}.${ext}`;
    // #endif
    if (file.size > props.field.size) {
      // #ifdef MP-WEIXIN
      file.path = await compressJPG(file);
      // #endif
      // #ifdef H5
      const current = (file.size / 1024 / 1024).toFixed(1);
      sendError(
        `文件过大(当前${
          current > 1 ? current + "MB" : (file.size / 1024).toFixed(1) + "KB"
        },上限${props.field.size_arg})`,
      );
      fuiDeleteFile(file);
      return;
      // #endif
    }
    const url = await Alioss.uploadUni({
      file,
      size: props.field.size,
      prefix: "img",
    });
    sendValue([...props.modelValue, url]);
    sendError("");
    return url;
  } catch (error) {
    console.log("error:", error);
    sendError(`上传错误：${error.message || error.errMsg}`);
    fuiDeleteFile(file);
  }
};
const fuiUploadVideoCallback = async (path, index) => {
  //上传的文件信息
  const file = fuiUploader.value.tempFiles[index];
  // console.log("fuiUploadVideoCallback file", file);
  if (file.size > props.field.size) {
    const current = (file.size / 1024 / 1024).toFixed(1);
    sendError(
      `视频过大(当前${
        current > 1 ? current + "MB" : (file.size / 1024).toFixed(1) + "KB"
      },上限${props.field.size_arg})`,
    );
    fuiDeleteFile(file);
    return;
  }
  const url = await Alioss.uploadUni({
    file,
    size: props.field.size,
    prefix: "video",
  });
  sendValue([...props.modelValue, url]);
  sendError("");
  return url;
};
const fuiCallUpload = async (index) => {
  // if (!fuiUploadStatus.value || fuiUploadStatus.value !== "preupload") {
  //   // uni.showToast({ title: "请选择需要上传的视频！" });
  //   console.log(index);
  //   return;
  // }
  const callback =
    props.field.media_type == "video" ? fuiUploadVideoCallback : fuiUploadCallback;
  await fuiUploader.value.upload(callback, index);
};
const fuiReUpload = async (e) => {
  console.log("fuiReUpload", e);
  await fuiCallUpload(e.index);
};
const fuiUploadSuccess = async (e) => {
  fuiUploadStatus.value = e.status;
  console.log("fuiUploadSuccess", e);
};
const fuiUploadError = async (e) => {
  fuiUploadStatus.value = e.status;
  console.log("fuiUploadError", e);
};
const fuiUploadPreview = async (e) => {
  console.log("fuiUploadPreview", e);
};
const clickOnSelectInput = () => {
  showSelect.value = true;
  setTimeout(() => uni.hideKeyboard(), 100);
};
const addressName = ref("");
const chooseLocation = async () => {
  const res = await uni.chooseLocation();
  // console.log(res);
  if (!res.name) {
    sendError(`获取位置失败，请点击地图下方地址列表`);
  } else if (!res.latitude || !res.longitude) {
    sendError(`获取坐标失败`);
  } else {
    sendError(``);
    sendValue(res);
    addressName.value = res.name;
  }
};
</script>
<template>
  <template v-if="fieldChoices">
    <fui-radio-group
      v-if="props.field.tag == 'radio'"
      @update:modelValue="
        sendValue($event);
        sendError('');
      "
      :modelValue="props.modelValue"
    >
      <fui-label
        v-for="(choice, index) in fieldChoices"
        :key="index"
        :inline="fieldInline"
        :margin="fieldInline ? ['0', '0'] : ['0.618em', '0']"
      >
        <fui-radio
          :checked="props.modelValue === choice.value"
          :scaleRatio="props.field.attrs.scaleRatio || 1"
          :value="choice.value"
        >
        </fui-radio>
        <fui-text
          :size="28"
          :text="choice.text"
          :padding="['0', '30rpx', '0', '16rpx']"
        ></fui-text>
      </fui-label>
    </fui-radio-group>
    <fui-checkbox-group
      v-else-if="isArrayField || props.field.tag == 'checkbox'"
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
    >
      <fui-label
        v-for="(choice, index) in fieldChoices"
        :key="index"
        :inline="fieldInline"
        :margin="fieldInline ? ['0', '0'] : ['0.618em', '0']"
      >
        <fui-checkbox
          :checked="props.modelValue === choice.value"
          :scaleRatio="props.field.attrs.scaleRatio || 1"
          :value="choice.value"
          borderRadius="8rpx"
        >
        </fui-checkbox>
        <fui-text
          :size="28"
          :text="choice.text"
          :padding="['0', '30rpx', '0', '16rpx']"
        ></fui-text>
      </fui-label>
    </fui-checkbox-group>
    <template v-else-if="props.field.attrs.button">
      <fui-input
        :bottomLeft="0"
        :borderBottom="true"
        :padding="[0]"
        :disabled="props.field.disabled"
        @focus="clickOnSelectInput"
        :borderColor="borderColor"
        :placeholder="props.field.attrs.placeholder"
        backgroundColor="transparent"
        :modelValue="fieldChoices.find((c) => c.value === props.modelValue)?.text"
      >
        <fui-button
          type="gray"
          width="200rpx"
          height="64rpx"
          size="28"
          text="选择"
          @click="showSelect = true"
        ></fui-button>
      </fui-input>
      <fui-select
        v-if="!props.field.attrs.picker"
        :show="showSelect"
        :options="fuiChoices"
        :title="`${props.field.label}`"
        :type="props.field.attrs.selectType || 'list'"
        @click="onSelectClick"
        @confirm="onSelectConfirm"
        @close="showSelect = false"
      >
      </fui-select>
      <fui-picker
        v-else
        :linkage="true"
        :options="fuiChoices"
        :show="showSelect"
        @change="onPickerConfirm"
        @cancel="showSelect = false"
      ></fui-picker>
    </template>
    <template v-else>
      <fui-list-cell
        arrow
        @click="showSelect = true"
        :padding="[0]"
        :bottomBorder="false"
        borderColor="transparent"
      >
        <template v-if="props.field.group">
          {{ pickerResultText }}
        </template>
        <template v-else>
          {{ fieldChoices.find((c) => c.value === props.modelValue)?.text }}
        </template>

        <view class="fui-list-input" :style="{ 'background-color': borderColor }"> </view>
      </fui-list-cell>
      <fui-picker
        linkage
        :options="fieldChoices"
        :layer="props.field.group?.length || 1"
        :show="showSelect"
        @change="onPickerConfirm"
        @cancel="showSelect = false"
      ></fui-picker>
    </template>
    <div
      v-if="!props.error && props.field.hint"
      class="field-hint"
      :style="props.field.attrs.hint_style"
    >
      {{ props.field.hint }}
    </div>
  </template>
  <template v-else-if="fieldType.startsWith('alioss')">
    <wx-avatar
      v-if="props.field.attrs.wx_avatar"
      @update:modelValue="sendValue"
      @update:error="sendError"
      :modelValue="{ url: props.modelValue, errMsg: props.error }"
      :size="props.field.size_arg"
    ></wx-avatar>
    <fui-upload-video
      v-else-if="props.field.media_type == 'video'"
      ref="fuiUploader"
      call-upload
      :max="fileLimit"
      :disabled="props.field.disabled"
      :radius="16"
      :modelValue="props.modelValue"
      :fileList="props.modelValue"
      :compressed="true"
      :maxDuration="props.field.attrs.maxDuration || 60"
      :width="props.field.attrs.width || 320"
      :height="props.field.attrs.height || 160"
      :extension2="['mp4', 'webm']"
      :size="props.field.size / 1024 / 1024"
      @update:modelValue="sendValue"
      @reupload="fuiReUpload"
      @complete="fuiUploadComplete"
      @success2="fuiUploadSuccess"
      @error="fuiUploadError"
      @preview="fuiUploadPreview"
    >
    </fui-upload-video>
    <fui-upload
      v-else
      ref="fuiUploader"
      call-upload
      :max="fileLimit"
      :disabled="props.field.disabled"
      :radius="16"
      :modelValue="props.modelValue"
      :fileList="props.modelValue"
      :sizeType="props.field.attrs.sizeType || ['compressed']"
      :suffix="props.field.attrs.suffix"
      :width="props.field.attrs.width"
      :height="props.field.attrs.height"
      :size="props.field.size / 1024 / 1024"
      @update:modelValue="sendValue"
      @reupload="fuiReUpload"
      @complete="fuiUploadComplete"
      @success2="fuiUploadSuccess"
      @error="fuiUploadError"
      @preview="fuiUploadPreview"
    >
    </fui-upload>
    <div
      v-if="!props.error && props.field.hint"
      class="field-hint"
      :style="props.field.attrs.hint_style"
    >
      {{ props.field.hint }}
    </div>
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
    @update:modelValue="
      sendValue($event);
      sendError('');
    "
    :modelValue="props.modelValue"
    :disabled="props.field.disabled"
    :placeholder="placeholder"
  />
  <uni-datetime-picker
    v-else-if="fieldType == 'datetime'"
    type="datetime"
    :clear-icon="false"
    @update:modelValue="
      sendValue($event);
      sendError('');
    "
    :modelValue="props.modelValue"
    :disabled="props.field.disabled"
    :placeholder="placeholder"
  />
  <picker
    v-else-if="fieldType == 'year_month'"
    @change="
      sendValue($event.detail.value);
      sendError('');
    "
    :value="props.modelValue"
    mode="date"
    fields="month"
  >
    <uni-easyinput
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :disabled="props.field.disabled"
      :borderColor="borderColor"
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
      :borderColor="borderColor"
      :placeholder="placeholder"
      suffixIcon="forward"
    />
  </picker>
  <template v-else-if="props.field.attrs.wx_phone">
    <fui-input
      :bottomLeft="0"
      :borderBottom="true"
      :padding="[0]"
      :disabled="props.field.disabled"
      :borderColor="borderColor"
      @blur="blurValidate(props.field.name)"
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :placeholder="placeholder"
      backgroundColor="transparent"
    >
      <fui-button
        type="gray"
        width="200rpx"
        height="64rpx"
        size="28"
        text="获取"
        open-type="getPhoneNumber"
        @getphonenumber="getPhoneNumber"
      >
      </fui-button>
    </fui-input>
  </template>
  <uni-easyinput
    v-else-if="props.field.attrs.useUniInput"
    @blur="blurValidate(props.field.name)"
    @update:modelValue="sendValue"
    :borderColor="borderColor"
    :error-message="props.error"
    :modelValue="props.modelValue"
    :disabled="props.field.disabled"
    :placeholder="placeholder"
    :type="easyType || 'text'"
  />
  <fui-textarea
    v-else-if="props.field.type == 'text' || props.field.attrs.input_type == 'textarea'"
    :bottomLeft="0"
    :textareaBorder="true"
    :padding="['18rpx', '18rpx']"
    :radius="16"
    :borderColor="borderColor"
    :disabled="props.field.disabled"
    :autoHeight="true"
    minHeight="200rpx"
    :maxlength="-1"
    :cursorSpacing="120"
    @blur="blurValidate(props.field.name)"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :placeholder="placeholder"
  ></fui-textarea>
  <fui-list-cell
    v-else-if="props.field.attrs.wx_lbs"
    arrow
    @click="chooseLocation"
    :padding="[0]"
    :bottomBorder="false"
    borderColor="transparent"
  >
    {{
      props.modelValue ? `${props.modelValue.name}（${props.modelValue.address}）` : ""
    }}
    <view class="fui-list-input" :style="{ 'background-color': borderColor }"> </view>
  </fui-list-cell>
  <fui-input
    v-else
    :bottomLeft="0"
    :borderBottom="true"
    :padding="[0]"
    :borderColor="borderColor"
    :disabled="props.field.disabled"
    :disabledStyle="true"
    @blur="blurValidate(props.field.name)"
    @update:modelValue="sendValue"
    :modelValue="props.modelValue"
    :placeholder="placeholder"
  ></fui-input>
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
  color: #666;
  font-size: 90%;
  padding: 6rpx 0;
  position: absolute;
}
</style>
