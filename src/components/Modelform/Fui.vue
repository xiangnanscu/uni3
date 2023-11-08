<script setup>
log("fui form setup");
const emit = defineEmits(["sendData", "successPost"]);
const props = defineProps({
  model: { type: [Object, Function], required: true },
  values: { type: Object, default: () => ({}) }, //	formdata，结合FormItem组件校验时必传
  errors: { type: Object, default: () => ({}) },
  syncValues: { type: Boolean, default: false },

  marginBottom: { type: String },
  bottomBorder: { type: Boolean, default: undefined },
  padding: { type: Array, default: () => ["30rpx", "0"] }, //	表单外层padding值（上，右，下，左），同css顺序,如：['30rpx','32rpx']
  disabled: { type: Boolean, default: false }, //是否禁用该表单内的所有组件,透明遮罩层
  errorPosition: { type: [String, Number], default: 1 }, //FormItem 组件错误提示定位方式方式：1-absolute 2-relative
  errorAlign: { type: String, default: "center" }, //FormItem 组件错误提示显示对齐方式，可选值：left、center、right
  labelWidth: { type: [String, Number] },
  labelSize: { type: [String, Number], default: 32 }, // 32是系统默认
  labelAlign: { type: String, default: "left" }, //left, right

  actionUrl: { type: String, required: false },
  successUrl: { type: [Object, String] },
  successMessage: { type: String },
  successUseRedirect: { type: Boolean, default: false },
  method: { type: String, default: "POST" }, // get
  hideSubmitButton: { type: Boolean, default: false },
  submitButtonText: { type: String, default: "提交" },
  submitButtonOpenType: { type: String, default: "" },
  errShowType: { type: String, default: "undertext" },
  showModal: { type: Boolean, default: false },
  // labelPosition: { type: String, default: "left" }, // top
  // errorFontSize: { type: [String, Number], default: 28 },
  // showFormError: { type: Boolean, default: false }, // 否显示校验错误信息，设置false时，可结合formItem组件显示校验信息
  // show: { type: Boolean, default: false }, // 否显示校验错误信息，设置false时，可结合formItem组件显示校验信息
  trigger: { type: String, default: "blur" },
  disableSubmit: { type: Function, default: () => false },
});
const deepcopy = (o) => JSON.parse(JSON.stringify(o));
const values = props.syncValues
  ? reactive(props.values)
  : reactive(deepcopy(props.values));
Object.assign(values, props.model.to_form_value(values, props.model.names));
const errors = reactive(props.errors);
const formRef = ref();
const submiting = ref(false);
const showArrow = ref();
const getFieldRule = (field, index) => {
  const rule = {
    name: field.name,
    rule: [],
    msg: [],
    validator: [
      {
        method: (value, formdata) => {
          field.validate(value, formdata);
          return true;
        },
      },
    ],
  };
  if (field.required) {
    rule.rule.push("required");
    rule.msg.push(`请${field.choices ? "选择" : "输入"}${field.label}`);
  }
  if (field.maxlength !== undefined) {
    rule.rule.push(`maxLength:${field.maxlength}`);
    rule.msg.push(`不能超过${field.maxlength}字`);
  }
  if (field.minlength !== undefined) {
    rule.rule.push(`minLength:${field.minlength}`);
    rule.msg.push(`不能少于${field.minlength}字`);
  }
  if (field.min !== undefined && field.max !== undefined) {
    rule.rule.push(`range[${field.min},${field.max}]`);
    rule.msg.push(`值限定在${field.min}和${field.max}之间`);
  }
  if (field.attrs?.isMobile) {
    rule.rule.push("isMobile");
    rule.msg.push(`请输入正确的手机号`);
  }
  if (field.attrs?.isEmail) {
    rule.rule.push("isEmail");
    rule.msg.push(`请输入正确的电子邮箱`);
  }
  if (field.type == "sfzh" || field.attrs?.isIdCard) {
    rule.rule.push("isIdCard");
    rule.msg.push(`请输入正确的身份证号`);
  }
  if (field.type == "integer" || field.type == "float" || field.attrs?.isNumber) {
    rule.rule.push("isNumber");
    rule.msg.push(`请输入数字`);
  }
  if (field.attrs?.isChinese) {
    rule.rule.push("isChinese");
    rule.msg.push(`请输入中文`);
  }
  if (field.attrs?.isUrl) {
    rule.rule.push("isUrl");
    rule.msg.push(`请输入正确的网址`);
  }
  return rule;
};
const formNames = computed(
  () => props.formNames || props.model.admin?.form_names || props.model.names,
);
const fieldsArray = computed(() =>
  formNames.value.map((name) => props.model.fields[name]),
);
const rules = computed(() => {
  const res = [];
  for (const field of fieldsArray.value) {
    res.push(getFieldRule(field));
  }
  return res;
});
const smartLabelWidth = computed(() => {
  if (props.labelWidth) {
    return props.labelWidth;
  } else {
    const maxLabelLength = fieldsArray.value
      .map((f) => f.label.length)
      .reduce((max, current) => Math.max(max, current));
    return `${(maxLabelLength + 2) * props.labelSize}`;
  }
});
const resetErrors = () => {
  for (const field of fieldsArray.value) {
    errors[field.name] = field.type == "array" ? [] : "";
  }
};
const shouldDisabled = computed(() => props.disableSubmit(values));
const validateField = async (name) => {
  const res = await formRef.value.validator(
    { [name]: values[name] },
    rules.value.filter((r) => r.name === name),
  );
  if (!res.isPassed) {
    errors[name] = res.errorMsg;
  }
};
const submit = async () => {
  resetErrors();
  let validateResult;
  try {
    validateResult = await formRef.value.validator(values, rules.value, true);
  } catch (error) {
    console.log("fui表单校验异常:", error);
    return;
  }
  if (!validateResult.isPassed) {
    console.log("fui表单校验错误:", validateResult.errorMsg);
    if (Array.isArray(validateResult.errorMsg)) {
      for (const { name, msg } of validateResult.errorMsg) {
        errors[name] = msg;
      }
    }
    return;
  }
  const formdata = props.model.to_post_value(values, props.model.names);
  // emit("sendData", formdata);
  if (!props.actionUrl) {
    return;
  }
  submiting.value = true;
  try {
    const response = await Http.post(props.actionUrl, {
      ...values, // TODO:这里先暂时不包含,观察应用情况
      ...formdata,
    });
    const respData =
      response.data.type == "uni_error" ? response.data.data : response.data;
    const successStuff = async () => {
      emit("successPost", respData);
      if (props.successUrl) {
        await utils.gotoPage({
          url: props.successUrl,
          redirect: props.successUseRedirect,
        });
      }
      if (props.successMessage) {
        await uni.showToast({ title: props.successMessage });
      }
    };
    if (typeof respData == "object") {
      const dataType = respData.type;
      if (dataType == "field_error") {
        errors[respData.name] = respData.message;
        if (props.showModal && props.errShowType !== "modal") {
          uni.showModal({
            title: `“${respData.label}”:${respData.message}`,
            showCancel: false,
          });
        }
      } else if (dataType == "field_error_batch") {
        errors[respData.name] = respData.message;
        if (props.showModal && props.errShowType !== "modal") {
          uni.showModal({
            title: `“${respData.label}”第${respData.index}行错误`,
            content: respData.message,
            showCancel: false,
          });
        }
      } else if (dataType == "model_errors") {
        Object.assign(errors, respData.errors);
        const messages = Object.entries(respData.errors)
          .map(([name, message]) => `${props.model.name_to_label[name]}: ${message}`)
          .join("\n");
        uni.showModal({
          title: `错误`,
          content: messages,
          showCancel: false,
        });
      } else {
        await successStuff();
      }
    } else if (response.data.type == "uni_error") {
      uni.showModal({
        title: "发生错误",
        content: respData,
        showCancel: false,
      });
    } else {
      await successStuff();
    }
  } catch (error) {
    console.error("uni-form error:", error);
    uni.showModal({
      title: "错误",
      content: error.errMsg || error.message,
      showCancel: false,
    });
  } finally {
    submiting.value = false;
  }
};
const getBottomBorder = (field) => {
  // console.log({ field, props });
  if (props.bottomBorder === undefined) {
    if (
      field.choices ||
      field.attrs.wx_phone ||
      field.wx_phone ||
      field.type.startsWith("alioss")
    ) {
      return true;
    } else {
      return false;
    }
  } else {
    return props.bottomBorder;
  }
};
// watch(
//   () => props.model,
//   (model) => {
//     log("model change");
//   },
// );
onMounted(() => {
  log("fui modelform mounted");
  resetErrors();
  // formRef.value.switchRealTimeValidator(true, rules.value);
});
</script>
<template>
  <fui-form
    ref="formRef"
    :model="values"
    :show="false"
    :disabled="props.disabled"
    :padding="props.padding"
    :error-position="props.errorPosition"
    :error-align="props.errorAlign"
    :label-align="props.labelAlign"
    :label-width2="smartLabelWidth"
  >
    <template v-for="field in fieldsArray" :key="field.name">
      <fui-form-item
        :prop2="field.name"
        :label-width="smartLabelWidth"
        :label-size="props.labelSize"
        :label="field.label"
        :asterisk2="field.required"
        :required="field.required"
        :arrow="showArrow"
        :highlight="showArrow"
        :marginBottom="props.marginBottom"
        :bottomBorder="false"
        :padding="field.attrs.padding || ['0rpx', '0rpx', '60rpx', '0rpx']"
      >
        <modelform-fui-widget
          :modelValue="values[field.name]"
          @update:modelValue="values[field.name] = $event"
          @blur:validate="validateField"
          v-model:error="errors[field.name]"
          :field="field"
        />
        <div v-if="errors[field.name]" class="field-error">
          {{ errors[field.name] }}
        </div>
        <div v-if="field.hint2" class="field-hint">
          {{ field.hint }}
        </div>
      </fui-form-item>
    </template>
    <fui-button
      v-if="!props.hideSubmitButton"
      :disabled="submiting || shouldDisabled"
      :text="props.submitButtonText"
      @click="submit"
      :open-type="props.submitButtonOpenType"
    >
    </fui-button>
  </fui-form>
</template>
<style scoped>
.field-hint {
  color: #666;
  font-size: 28rpx;
  padding: 6rpx 0;
  position: absolute;
}
.field-error {
  color: red;
  font-weight: bold;
  font-size: 28rpx;
  padding: 6rpx 0;
  position: absolute;
}
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