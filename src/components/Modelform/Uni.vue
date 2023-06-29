<script setup>
import { onReady } from "@dcloudio/uni-app";

const emit = defineEmits(["sendData", "successPost", "validate"]);
const props = defineProps({
  model: { type: [Object, Function], required: true },
  values: { type: Object, default: () => ({}) },
  errors: { type: Object, default: () => ({}) },
  syncValues: { type: Boolean, default: false },
  actionUrl: { type: String, required: false },
  successUrl: { type: [Object, String] },
  successUseRedirect: { type: Boolean, default: false },
  method: { type: String, default: "POST" }, // get
  hideSubmitButton: { type: Boolean, default: false },
  submitButtonText: { type: String, default: "提交" },
  errShowType: { type: String, default: "undertext" },
  showModal: { type: Boolean, default: false },
  labelPosition: { type: String, default: "left" }, // top
  labelWidth: { type: [String, Number], default: "5em" },
  labelAlign: { type: String, default: "right" }, //center, right
  trigger: { type: String, default: "blur" },
  labelCol: { type: Number, default: 3 }
});
const deepcopy = (o) => JSON.parse(JSON.stringify(o));
const values = props.syncValues
  ? reactive(props.values)
  : reactive(deepcopy(props.values));
Object.assign(values, props.model.toFormValue(values, props.model.names));
const errors = reactive(props.errors);
const formRef = ref();
const getFieldRules = (field) => [
  { required: field.required, errorMessage: `必须填写${field.label}` },
  {
    validateFunction: function (rule, value, data, callback) {
      data[field.name] = field.validate(value, data);
      return true;
    }
  }
];
const fieldsArray = computed(() =>
  props.model.names.map((name) => props.model.fields[name])
);
const formsItemRefs = {};
const rules = {};
const resetErrors = () => {
  for (const field of fieldsArray.value) {
    errors[field.name] = field.type == "array" ? [] : "";
  }
};
resetErrors();
for (const field of fieldsArray.value) {
  formsItemRefs[field.name] = ref(null);
  rules[field.name] = {
    rules: getFieldRules(field)
  };
}

// #ifdef MP-WEIXIN
onReady(() => {
  console.log("onReady modelform uni");
  formRef.value.setRules(rules);
});
// #endif
const vm = getCurrentInstance();
// #ifdef H5
onMounted(() => {
  console.log("onMounted modelform uni");
  formRef.value.setRules(rules);
});
// #endif

const submiting = ref(false);
const submit = async () => {
  resetErrors();
  formRef.value.clearValidate();
  const cleanedData = await formRef.value.validate();
  const formdata = props.model.toPostValue(cleanedData, props.model.names);
  if (vm.vnode.props.onSendData) {
    emit("sendData", formdata);
  }
  if (!props.actionUrl) {
    return;
  }
  submiting.value = true;
  try {
    const response = await Http.post(props.actionUrl, {
      ...values,
      ...formdata
    });
    const realData =
      response.data.type == "uni_error" ? response.data.data : response.data;
    const successStuff = () => {
      emit("successPost", realData);
      if (props.successUrl) {
        utils.gotoPage({
          url: props.successUrl,
          redirect: props.successUseRedirect
        });
      }
    };
    if (typeof realData == "object") {
      const dataType = realData.type;
      if (dataType == "field_error") {
        errors[realData.name] = realData.message;
        if (props.showModal && props.errShowType !== "modal") {
          uni.showModal({
            title: `“${realData.label}”:${realData.message}`,
            showCancel: false
          });
        }
      } else if (dataType == "field_error_batch") {
        errors[realData.name] = realData.message;
        if (props.showModal && props.errShowType !== "modal") {
          uni.showModal({
            title: `“${realData.label}”第${realData.index}行错误`,
            content: realData.message,
            showCancel: false
          });
        }
      } else if (dataType == "model_errors") {
        Object.assign(errors, realData.errors);
        const messages = Object.entries(realData.errors)
          .map(
            ([name, message]) => `${props.model.nameToLabel[name]}: ${message}`
          )
          .join("\n");
        uni.showModal({
          title: `错误`,
          content: messages,
          showCancel: false
        });
      } else {
        successStuff();
      }
    } else if (response.data.type == "uni_error") {
      uni.showModal({
        title: "发生错误",
        content: realData,
        showCancel: false
      });
    } else {
      successStuff();
    }
  } catch (error) {
    console.error("uni-form error:", error);
    uni.showModal({
      title: "错误",
      content: error.errMsg || error.message,
      showCancel: false
    });
  } finally {
    submiting.value = false;
  }
};
</script>
<template>
  <uni-forms
    ref="formRef"
    :model="values"
    :err-show-type="props.errShowType"
    :label-align="props.labelAlign"
    :label-position="props.labelPosition"
    :label-width="props.labelWidth"
    @validate="emit('validate', $event)"
  >
    <template v-for="(field, index) in fieldsArray" :key="index">
      <template v-if="field.type == 'array' && !field.choices">
        <template v-for="(value, index) in values[field.name]" :key="index">
          <uni-forms-item
            :ref="(el) => (formsItemRefs[field.name + index] = el)"
            :label="index > 0 ? '' : field.label"
            :required="field.required"
            :name="[field.name, index]"
            :error-message="errors[field.name][index]"
            :rules="getFieldRules(field.arrayField)"
            style2="margin-bottom: 2px"
          >
            <div
              style="display: flex; flex-direction: row; align-items: center"
            >
              <div style="flex: auto; width: 80%">
                <modelform-uni-widget
                  v-model="values[field.name][index]"
                  v-model:error="errors[field.name][index]"
                  @blur:validate="
                    formsItemRefs[field.name + index].onFieldChange($event)
                  "
                  :field="field.arrayField"
                />
              </div>
              <uni-icons
                @click="values[field.name].splice(index, 1)"
                style="
                  flex: auto;
                  cursor: pointer;
                  text-align: center;
                  color: red;
                "
                type="closeempty"
                style2="color: red"
              ></uni-icons>
            </div>
          </uni-forms-item>
        </template>
        <uni-forms-item
          :label="values[field.name]?.length > 0 ? '' : field.label"
        >
          <x-button
            size="mini"
            @click="values[field.name].push(field.getDefault())"
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
          field.type == 'array'
            ? errors[field.name].join('')
            : errors[field.name]
        "
      >
        <modelform-uni-widget
          :modelValue="values[field.name]"
          @update:modelValue="values[field.name] = $event"
          @blur:validate="formsItemRefs[field.name].onFieldChange($event)"
          v-model:error="errors[field.name]"
          :field="field"
        />
      </uni-forms-item>
    </template>
    <x-button
      v-if="!props.hideSubmitButton"
      :disabled="submiting"
      @click="submit"
    >
      {{ props.submitButtonText }}
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
