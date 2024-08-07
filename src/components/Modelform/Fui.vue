<script setup>
import { repr } from "~/lib/utils.mjs";

const emit = defineEmits(["sendData", "successPost"]);
const slots = useSlots();
console.log("slots", slots);
const props = defineProps({
  model: { type: [Object, Function], required: true },
  values: { type: Object, default: () => ({}) }, //	formdata，结合FormItem组件校验时必传
  errors: { type: Object, default: () => ({}) },
  syncValues: { type: Boolean, default: false },
  valuesHook: { type: Function },
  names: { type: Array },
  errorReport: { type: Function },

  actionUrl: { type: String, required: false },
  successUrl: { type: [Object, String] },
  successMessage: { type: String },
  successUseRedirect: { type: Boolean, default: true },
  method: { type: String, default: "POST" }, // get
  hideSubmitButton: { type: Boolean, default: false },
  submitButtonText: { type: String, default: "提交" },
  submitButtonOpenType: { type: String, default: "" },
  errShowType: { type: String, default: "undertext" },
  showModal: { type: Boolean, default: false },
  trigger: { type: String, default: "blur" },
  disableSubmit: { type: Function, default: () => false },

  marginBottom: { type: String },
  bottomBorder: { type: Boolean, default: undefined },
  padding: { type: Array, default: () => ["30rpx", "0"] }, //	表单外层padding值（上，右，下，左），同css顺序,如：['30rpx','32rpx']
  disabled: { type: Boolean, default: false }, //是否禁用该表单内的所有组件,透明遮罩层
  errorPosition: { type: [String, Number], default: 1 }, //FormItem 组件错误提示定位方式方式：1-absolute 2-relative
  errorAlign: { type: String, default: "center" }, //FormItem 组件错误提示显示对齐方式，可选值：left、center、right
  labelColor: { type: String, default: "" },
  labelWeight: { type: String, default: "" },
  labelPosition: { type: String, default: "" }, // top,left
  labelWidth: { type: [String, Number] },
  labelSize: { type: [String, Number], default: 32 }, // 32是系统默认
  labelAlign: { type: String, default: "left" }, //left, right
});
const deepcopy = (o) => JSON.parse(JSON.stringify(o));
const values = props.syncValues ? reactive(props.values) : reactive(deepcopy(props.values));
const formNames = computed(() => props.names || props.model.admin?.form_names || props.model.names);
Object.assign(values, props.model.to_form_value(values, formNames.value));
const fieldsArray = computed(() => formNames.value.map((name) => props.model.fields[name]).filter((e) => e));
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
const rules = computed(() => {
  const res = [];
  for (const field of fieldsArray.value) {
    res.push(getFieldRule(field));
  }
  return res;
});
const errors = reactive(props.errors);
const formRef = ref();
const submiting = ref(false);
const updateValues = (data) => {
  Object.assign(values, data);
};
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
const smartLabelPosition = computed(() => {
  if (props.labelPosition) {
    return props.labelPosition;
  } else {
    return !fieldsArray.value.every((f) => f.type !== "table") ? "top" : "left";
  }
});
const showArrow = ref();
const resetErrors = () => {
  fieldsArray.value.forEach((field) => {
    if (field.type === "array" && field.field) {
      errors[field.name] = [...Array(getArrayKeyNumber(field)).keys()].map(() => "");
    } else {
      errors[field.name] = "";
    }
  });
};
resetErrors();
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
    await props.errorReport?.(error);
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
  const formdata = props.model.to_post_value(values, formNames.value);
  emit("sendData", formdata);
  if (props.valuesHook) {
    Object.assign(formdata, props.valuesHook({ data: formdata, model: props.model }));
  }
  if (!props.actionUrl) {
    return;
  }
  submiting.value = true;
  try {
    const postData = {
      ...values,
      ...formdata,
    };
    const respData = await usePost(props.actionUrl, postData);
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
  } catch (error) {
    if (error.type == "uni_error") {
      const formerror = error.data;
      const dataType = formerror.type;
      if (dataType == "field_error") {
        errors[formerror.name] = formerror.message;
        if (props.showModal) {
          uni.showModal({
            title: `“${formerror.label}”:${formerror.message}`,
            showCancel: false,
          });
        }
      } else if (dataType == "field_error_batch") {
        errors[formerror.name] = formerror.message;
        if (props.showModal && props.errShowType !== "modal") {
          uni.showModal({
            title: `“${formerror.label}”第${formerror.index}行错误`,
            content: formerror.message,
            showCancel: false,
          });
        }
      } else if (dataType == "model_errors") {
        Object.assign(errors, formerror.errors);
        const messages = Object.entries(formerror.errors)
          .map(([name, message]) => `${props.model.name_to_label[name]}: ${message}`)
          .join("\n");
        uni.showModal({
          title: `提交错误`,
          content: messages,
          showCancel: false,
        });
      } else {
        uni.showModal({
          title: "提交错误",
          content: typeof formerror == "string" ? formerror : JSON.stringify(formerror),
          showCancel: false,
        });
      }
    } else {
      if (props.errorReport) {
        try {
          await props.errorReport(error);
        } catch (reportError) {
          console.log("errorReport error:", reportError);
        }
      }
      throw error; // 抛给全局errorHandler
    }
  } finally {
    submiting.value = false;
  }
};
const getBottomBorder = (field) => {
  // console.log({ field, props });
  if (props.bottomBorder === undefined) {
    if (field.choices || field.attrs.wx_phone || field.wx_phone || field.type.startsWith("alioss")) {
      return true;
    } else {
      return false;
    }
  } else {
    return props.bottomBorder;
  }
};
const ready = ref();
const topLabelStyle = computed(() => ({
  fontWeight: props.labelWeight,
  marginBottom: "5px",
  fontSize: props.labelSize + "rpx",
  color: props.labelColor,
}));
onMounted(async () => {
  for (const field of fieldsArray.value) {
    if (typeof field.choices == "function") {
      field.choices = await field.choices();
    }
    // #ifdef H5
    if (field.attrs?.wx_phone) field.attrs.wx_phone = false;
    if (field.attrs?.wx_avatar) field.attrs.wx_avatar = false;
    // #endif
  }
  resetErrors();
  ready.value = true;
});
</script>
<template>
  <fui-form
    v-if="ready"
    ref="formRef"
    :model="values"
    :show="false"
    :disabled="props.disabled"
    :padding="props.padding"
    :error-position="props.errorPosition"
    :error-align="props.errorAlign"
    :label-align2="props.labelAlign"
    :label-width2="smartLabelWidth"
  >
    <template v-for="field in fieldsArray" :key="field.name">
      <fui-form-item
        :prop2="field.name"
        :asterisk2="field.required"
        :labelWeight="props.labelWeight"
        :labelAlign="props.labelAlign"
        :labelWidth="smartLabelWidth"
        :labelSize="props.labelSize"
        :label="field.type == 'table' ? '' : smartLabelPosition == 'left' ? field.label : ''"
        :labelColor="props.labelColor"
        :required="field.required"
        :arrow="showArrow"
        :highlight="showArrow"
        :marginBottom="props.marginBottom"
        :bottomBorder="false"
        :padding="field.attrs.padding || ['0rpx', '0rpx', '60rpx', '0rpx']"
      >
        <div
          v-if="field.type !== 'table' && smartLabelPosition == 'top'"
          :class="{ [`top-label-required-${field.required}`]: true }"
          :style="topLabelStyle"
        >
          {{ field.label }}
        </div>
        <modelform-fui-table-field
          v-if="field.type == 'table'"
          :modelValue="values[field.name]"
          @update:modelValue="values[field.name] = $event"
          v-model:error="errors[field.name]"
          :showTableHeader="!!field.attrs.showTableHeader"
          :labelStyle="topLabelStyle"
          :labelWeight="labelWeight"
          :labelPosition="smartLabelPosition"
          :labelAlign="props.labelAlign"
          :labelSize="props.labelSize"
          :field="field"
        />
        <modelform-fui-widget
          v-else
          :modelValue="values[field.name]"
          @update:modelValue="values[field.name] = $event"
          @update:values="updateValues"
          v-model:error="errors[field.name]"
          :field="field"
          @blur:validate="validateField"
        />
        <div v-if="errors[field.name]" class="field-error">
          {{ errors[field.name] }}
        </div>
        <div v-if="field.hint2" class="field-hint">
          {{ field.hint }}
        </div>
        <slot name="helpText" :field="field"> </slot>
      </fui-form-item>
    </template>
    <fui-button
      v-if="!props.hideSubmitButton"
      :disabled="submiting || shouldDisabled"
      :text2="props.submitButtonText"
      @click="submit"
      :open-type="props.submitButtonOpenType"
    >
      <template v-if="submitButtonText.length == 2">
        {{ submitButtonText[0] }} &nbsp; {{ submitButtonText[1] }}
      </template>
      <template v-else>
        {{ submitButtonText }}
      </template>
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
.top-label-required-true::before {
  content: "*";
  color: red;
  margin-right: 5px;
}
.top-label-required-false::before {
  content: "";
  color: transparent;
  margin-right: 5px;
}
</style>
