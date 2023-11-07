<script setup>
//TODO:需注意多表单共用model的情况.当前存在field.choices和field._realValue会修改field
const emit = defineEmits(["update:modelValue", "update:error", "blur:validate"]);
const props = defineProps({
  field: { type: Object, required: true },
  modelValue: { required: true },
  error: { type: String, default: "" },
  borderColor: { type: String, default: "#ccc" },
});
// const uniFormItem = inject("uniFormItem", null);
const field = props.field;
const fieldType = props.field.type;
const isArrayField = computed(() => fieldType === "array");
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
  () => easyInputTypeMap[field.type] || easyInputTypeMap[field.input_type],
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
let wxPhoneDisabled = field.disabled === undefined ? false : field.disabled;
// #ifdef H5
wxPhoneDisabled = false;
field.attrs.wx_phone = false;
field.attrs.wx_avatar = false;
// #endif
const placeholder = computed(() => field.attrs?.placeholder || field.hint);
const ready = ref(); //确保一些需要提前异步获取到数据加载完之后再渲染
const fieldInline = computed(() => !!field.attrs.inline);
const showArrow = computed(() => field.choices && field.tag == "select");
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

const onPickerConfirm = (e) => {
  // log("onPickerConfirm", e);
  sendValue(e.value);
  sendError("");
  showSelect.value = false;
};
if (showArrow) {
  formItemEvents.click = (e) => {
    showSelect.value = true;
  };
}
const fieldChoices = computed(() =>
  (fieldType !== "array" ? field.choices : field.field.choices)?.map((e) => ({
    text: e.label,
    value: e.value,
  })),
);
const fuiChoices = computed(() =>
  fieldChoices.value.map((e) => ({
    ...e,
    checked: e.value === props.modelValue,
  })),
);
onBeforeMount(async () => {
  //onBeforeMount 比template后调用
  // console.log("widget onBeforeMount start");
  if (typeof field.choices == "function") {
    field.choices = await field.choices();
  }
  ready.value = true;
});
const fuiUploader = ref();
const fuiUploadStatus = ref();
const fileLimit = computed(() => (fieldType.endsWith("_list") ? field.limit || 9 : 1));
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
const fuiUploadCallback = async (file) => {
  //上传的文件信息
  // #ifdef MP-WEIXIN
  // 微信平台file对象只有path和size属性
  const [_, name, ext] = file.path.match(/\/(\w+)\.(\w+)$/);
  file.name = `${name}.${ext}`;
  // #endif
  if (file.size > field.size) {
    const current = (file.size / 1024 / 1024).toFixed(1);
    sendError(
      `文件过大(当前${
        current > 1 ? current + "MB" : (file.size / 1024).toFixed(1) + "KB"
      },上限${field.size_arg})`,
    );
    fuiDeleteFile(file);
    return;
  }
  const url = await Alioss.uploadUni({
    file,
    size: field.size,
    prefix: "img",
  });
  sendValue([...props.modelValue, url]);
  sendError("");
  return url;
};
const fuiUploadVideoCallback = async (path, index) => {
  //上传的文件信息
  const file = fuiUploader.value.tempFiles[index];
  // console.log("fuiUploadVideoCallback file", file);
  if (file.size > field.size) {
    const current = (file.size / 1024 / 1024).toFixed(1);
    sendError(
      `文件过大(当前${
        current > 1 ? current + "MB" : (file.size / 1024).toFixed(1) + "KB"
      },上限${field.size_arg})`,
    );
    fuiDeleteFile(file);
    return;
  }
  const url = await Alioss.uploadUni({
    file,
    size: field.size,
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
    field.media_type == "video" ? fuiUploadVideoCallback : fuiUploadCallback;
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
  <template v-if="ready">
    <template v-if="fieldChoices">
      <template v-if="field.tag == 'select'">
        <fui-input
          :bottomLeft="0"
          :borderBottom="true"
          :padding="[0]"
          :disabled="false"
          @focus="clickOnSelectInput"
          :borderColor="props.borderColor"
          :placeholder="field.attrs.placeholder"
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
          v-if="!field.attrs.picker"
          :show="showSelect"
          :options="fuiChoices"
          :title="`${field.label}`"
          :type="field.attrs.selectType || 'list'"
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
      <fui-radio-group
        v-else-if="field.tag == 'radio'"
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
            :scaleRatio="field.attrs.scaleRatio || 1"
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
        v-else-if="isArrayField || field.tag == 'checkbox'"
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
            :scaleRatio="field.attrs.scaleRatio || 1"
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
      <div v-if="!props.error && field.hint" class="field-hint">
        {{ field.hint }}
      </div>
    </template>
    <template v-else-if="fieldType.startsWith('alioss')">
      <wx-avatar
        v-if="field.attrs.wx_avatar"
        @update:modelValue="sendValue"
        @update:error="sendError"
        :modelValue="{ url: props.modelValue, errMsg: props.error }"
        :size="field.size_arg"
      ></wx-avatar>
      <fui-upload-video
        v-else-if="field.media_type == 'video'"
        ref="fuiUploader"
        call-upload
        :max="fileLimit"
        :disabled="field.disabled"
        :radius="16"
        :modelValue="props.modelValue"
        :fileList="props.modelValue"
        :compressed="true"
        :maxDuration="field.attrs.maxDuration || 60"
        :width="field.attrs.width || 320"
        :height="field.attrs.height || 160"
        :extension2="['mp4', 'webm']"
        :size2="field.size / 1024 / 1024"
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
        :disabled="field.disabled"
        :radius="16"
        :modelValue="props.modelValue"
        :fileList="props.modelValue"
        :sizeType="field.attrs.sizeType || ['compressed']"
        :suffix="field.attrs.suffix"
        :width="field.attrs.width"
        :height="field.attrs.height"
        :size2="field.size / 1024 / 1024"
        @update:modelValue="sendValue"
        @reupload="fuiReUpload"
        @complete="fuiUploadComplete"
        @success2="fuiUploadSuccess"
        @error="fuiUploadError"
        @preview="fuiUploadPreview"
      >
      </fui-upload>
      <div v-if="!props.error && field.hint" class="field-hint">
        {{ field.hint }}
      </div>
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
      @update:modelValue="
        sendValue($event);
        sendError('');
      "
      :modelValue="props.modelValue"
      :disabled="field.disabled"
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
      :disabled="field.disabled"
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
        :disabled="field.disabled"
        :borderColor="props.borderColor"
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
        :borderColor="props.borderColor"
        :placeholder="placeholder"
        suffixIcon="forward"
      />
    </picker>
    <template v-else-if="field.attrs.wx_phone">
      <fui-input
        :bottomLeft="0"
        :borderBottom="true"
        :padding="[0]"
        :disabled="wxPhoneDisabled"
        :borderColor="props.borderColor"
        @blur="blurValidate(field.name)"
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
      v-else-if="field.attrs.useUniInput"
      @blur="blurValidate(field.name)"
      @update:modelValue="sendValue"
      :borderColor="props.borderColor"
      :error-message="props.error"
      :modelValue="props.modelValue"
      :disabled="field.disabled"
      :placeholder="placeholder"
      :type="easyType || 'text'"
    />
    <fui-textarea
      v-else-if="field.type == 'text' || field.attrs.input_type == 'textarea'"
      :bottomLeft="0"
      :textareaBorder="true"
      :padding="['18rpx', '18rpx']"
      :radius="16"
      :borderColor="props.borderColor"
      :disabled="field.disabled"
      :autoHeight="true"
      minHeight="200rpx"
      :cursorSpacing="120"
      @blur="blurValidate(field.name)"
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :placeholder="placeholder"
    ></fui-textarea>
    <fui-input
      v-else-if="field.attrs.wx_lbs"
      :bottomLeft="0"
      :borderBottom="true"
      :padding="[0]"
      :disabled="true"
      :borderColor="props.borderColor"
      :placeholder="placeholder || '点击右侧定位'"
      :size="28"
      backgroundColor="transparent"
      :modelValue="addressName"
    >
      <fui-button
        type="gray"
        width="200rpx"
        height="64rpx"
        size="28"
        text="定位"
        @click="chooseLocation"
      ></fui-button>
    </fui-input>
    <fui-input
      v-else
      :bottomLeft="0"
      :borderBottom="true"
      :padding="[0]"
      :borderColor="props.borderColor"
      :disabled="field.disabled"
      :disabledStyle="true"
      @blur="blurValidate(field.name)"
      @update:modelValue="sendValue"
      :modelValue="props.modelValue"
      :placeholder="placeholder"
    ></fui-input>
  </template>
</template>
<style scoped>
.field-hint {
  color: #666;
  font-size: 90%;
  padding: 6rpx 0;
  position: absolute;
}
</style>
