<script setup>
import { onReady } from "@dcloudio/uni-app";

const emit = defineEmits(["sendData", "successPost", "validate"]);
const props = defineProps({
  model: { type: [Object, Function], required: true },
  values: { type: Object, default: () => ({}) },
  errors: { type: Object, default: () => ({}) },
  syncValues: { type: Boolean, default: false },
  valuesHook: { type: Function },
  names: { type: Array },

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
  trigger: { type: String, default: "blur" },
  disableSubmit: { type: Function, default: () => false },

  labelPosition: { type: String, default: "left" }, // top
  labelWidth: { type: [String, Number] },
  labelAlign: { type: String, default: "right" }, //center, right
});
const deepcopy = (o) => JSON.parse(JSON.stringify(o));
const values = props.syncValues
  ? reactive(props.values)
  : reactive(deepcopy(props.values));
const formNames = computed(
  () => props.names || props.model.admin?.form_names || props.model.names,
);
Object.assign(values, props.model.to_form_value(values, formNames.value));
const fieldsArray = computed(() =>
  formNames.value.map((name) => props.model.fields[name]).filter((e) => e),
);
const getFieldRules = (field, index) => [
  { required: field.required, errorMessage: `必须填写${field.label}` },
  {
    validateFunction: function (rule, value, data, callback) {
      const name = index === undefined ? field.name : field.name + "_" + index;
      data[name] = field.validate(value, data);
      return true;
    },
  },
];
const rules = computed(() => {
  const res = {};
  for (const field of fieldsArray.value) {
    formsItemRefs[field.name] = ref(null);
    res[field.name] = {
      rules: getFieldRules(field),
    };
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
    return `${maxLabelLength + 2}em`;
  }
});
const formsItemRefs = {};
const resetErrors = () => {
  for (const field of fieldsArray.value) {
    errors[field.name] = field.type == "array" ? [] : "";
  }
};
resetErrors();
const shouldDisabled = computed(() => props.disableSubmit(values));
const ready = ref();
const prepareForm = async () => {
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
};
watch(formRef, (form) => {
  if (form) {
    form.setRules(rules.value);
  }
});
//TODO: 需要watch:rules以应对model变化
// #ifdef MP-WEIXIN
onReady(prepareForm);
// #endif
// #ifdef H5
onMounted(prepareForm);
// #endif
const submit = async () => {
  resetErrors();
  formRef.value.clearValidate();
  const cleanedData = await formRef.value.validate();
  const formdata = props.model.to_post_value(cleanedData, formNames.value);
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
    console.error("uni-form error:", utils.repr(error));
    if (error.type == "uni_error") {
      const formerror = error.data;
      const dataType = formerror.type;
      if (dataType == "field_error") {
        errors[formerror.name] = formerror.message;
        if (props.showModal && props.errShowType !== "modal") {
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
          title: `错误`,
          content: messages,
          showCancel: false,
        });
      } else {
        uni.showModal({
          title: "错误",
          content: JSON.stringify(formerror),
          showCancel: false,
        });
      }
    } else {
      uni.showModal({
        title: "错误",
        content: error.errMsg || error.message,
        showCancel: false,
      });
    }
  } finally {
    submiting.value = false;
  }
};
</script>
<template>
  <uni-forms
    v-if="ready"
    ref="formRef"
    :model="values"
    :err-show-type="props.errShowType"
    :label-align="props.labelAlign"
    :label-position="props.labelPosition"
    :label-width="smartLabelWidth"
    @validate="emit('validate', $event)"
  >
    <template v-for="(field, fieldIndex) in fieldsArray" :key="fieldIndex">
      <template v-if="field.type == 'array' && !field.choices">
        <template v-for="(value, index) in values[field.name]" :key="index">
          <uni-forms-item
            :ref="(el) => (formsItemRefs[field.name + index] = el)"
            :label="index > 0 ? '' : field.label"
            :required="field.required"
            :name="[field.name, index]"
            :error-message="errors[field.name][index]"
            :rules="getFieldRules(field.field, index)"
            style2="margin-bottom: 2px"
          >
            <div style="display: flex; flex-direction: row; align-items: center">
              <div style="flex: auto; width: 80%">
                <modelform-uni-widget
                  v-model="values[field.name][index]"
                  v-model:error="errors[field.name][index]"
                  @blur:validate="formsItemRefs[field.name + index].onFieldChange($event)"
                  @update:values="updateValues"
                  :field="field.field"
                />
              </div>
              <uni-icons
                @click="values[field.name].splice(index, 1)"
                style="flex: auto; cursor: pointer; text-align: center; color: red"
                type="closeempty"
                style2="color: red"
              ></uni-icons>
            </div>
          </uni-forms-item>
        </template>
        <uni-forms-item :label="values[field.name]?.length > 0 ? '' : field.label">
          <x-button
            size="mini"
            :text="`添加${field.label}`"
            @click="values[field.name].push(field.get_default())"
          >
            <uni-icons type="plusempty" style="color: #fff"></uni-icons>
            添加{{ field.label }}
          </x-button>
        </uni-forms-item>
      </template>
      <template v-else-if="field.type == 'table'">
        <uni-forms-item
          :ref="(el) => (formsItemRefs[field.name] = el)"
          :label="field.label"
          :required="field.required"
          :name="field.name"
          :error-message="errors[field.name]"
        >
          <modelform-uni-table-field
            :modelValue="values[field.name]"
            @update:modelValue="
              formsItemRefs[field.name].onFieldChange($event);
              values[field.name] = $event;
            "
            v-model:error="errors[field.name]"
            :field="field"
          />
        </uni-forms-item>
      </template>
      <uni-forms-item
        v-else
        :ref="(el) => (formsItemRefs[field.name] = el)"
        :label="field.label"
        :required="field.required"
        :name="field.name"
        :error-message="
          field.type == 'array' ? errors[field.name].join('') : errors[field.name]
        "
      >
        <modelform-uni-widget
          :modelValue="values[field.name]"
          @update:modelValue="values[field.name] = $event"
          @blur:validate="formsItemRefs[field.name].onFieldChange($event)"
          @update:values="updateValues"
          v-model:error="errors[field.name]"
          :field="field"
        />
      </uni-forms-item>
    </template>
    <x-button
      v-if="!props.hideSubmitButton"
      :disabled="submiting || shouldDisabled"
      :text="props.submitButtonText"
      @click="submit"
      :open-type="props.submitButtonOpenType"
      size="default"
    >
      <template v-if="submitButtonText.length == 2">
        {{ submitButtonText[0] }} &nbsp; {{ submitButtonText[1] }}
      </template>
      <template v-else>
        {{ submitButtonText }}
      </template>
    </x-button>
  </uni-forms>
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
