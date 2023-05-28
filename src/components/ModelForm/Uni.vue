<script setup>
import { useStore } from "@/store";
import { onReady } from "@dcloudio/uni-app";
import { repr } from "@/lib/utils.mjs";

const emit = defineEmits(["submit", "successPost", "validate"]);
const props = defineProps({
  model: { type: [Object, Function], required: true },
  values: { type: Object, default: () => ({}) },
  errors: { type: Object, default: () => ({}) },
  syncValues: { type: Boolean, default: false },
  actionUrl: { type: String, required: false },
  method: { type: String, default: "POST" },
  hideSubmitButton: { type: Boolean, default: false },
  buttonText: { type: String },
  itemWidth: { type: String },
  successRoute: { type: [Object, String] },
  layout: { type: String, default: "horizontal" }, // horizontal
  trigger: { type: String, default: "blur" },
  labelCol: { type: Number, default: 3 }
});
const attrs = useAttrs();
const deepcopy = (o) => JSON.parse(JSON.stringify(o));
const values = props.syncValues
  ? reactive(props.values)
  : reactive(deepcopy(props.values));
Object.assign(values, props.model.toFormValue(values, props.model.names));
const errors = reactive(props.errors);
const { loading } = storeToRefs(useStore());
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
for (const field of fieldsArray.value) {
  const name = field.name;
  if (field.type == "array") {
    errors[name] = [];
  }
  formsItemRefs[name] = ref(null);
  rules[name] = {
    rules: getFieldRules(field)
  };
}

// #ifdef MP-WEIXIN
onReady(() => {
  console.log("onReady modelform uni");
  formRef.value.setRules(rules);
});
// #endif

// #ifdef H5
onMounted(() => {
  console.log("onMounted modelform uni");
  formRef.value.setRules(rules);
});
// #endif

const formError = ref("");
const submiting = ref(false);
const clearBackendErrors = () => {
  formError.value = "";
  for (const key in errors) {
    errors[key] = "";
  }
};
const submit = async () => {
  formRef.value.clearValidate();
  clearBackendErrors();
  let cleanedData;
  try {
    cleanedData = await formRef.value.validate();
  } catch (error) {
    console.error(error);
    return;
  }
  const data = props.model.toPostValue(cleanedData, props.model.names);
  if (attrs.onSendData) {
    console.log("onSendData defined", data);
    emit("sendData", data);
  }
  if (!props.actionUrl) {
    return;
  }
  submiting.value = true;
  try {
    // await Http.post(props.actionUrl, data);
    const res = await uni.request({
      url: props.actionUrl,
      method: "post",
      data
    });
    console.log({ res });
  } catch (error) {
    console.error("??", error);
    if (error.name == "AxiosError") {
      const { data, status } = error.response;
      if (status == 422) {
        errors[data.name] = data.message;
      } else {
        formError.value = typeof data == "object" ? JSON.stringify(data) : data;
      }
    } else {
      uni.showToast({
        title: error.errMsg || error.message,
        content: "haha",
        icon: "error"
      });
    }
  } finally {
    submiting.value = false;
  }
};
</script>
<template>
  <uni-forms
    ref="formRef"
    :model="values"
    @validate="emit('validate', $event)"
    label-width="5em"
    label-align="right"
  >
    <template v-for="(field, index) in fieldsArray" :key="index">
      <template v-if="field.type == 'array'">
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
                <model-form-uni-widget
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
          <button
            type="primary"
            size="mini"
            @click="values[field.name].push(field.getDefault())"
          >
            <uni-icons type="plusempty" style="color: #fff"></uni-icons>
            添加{{ field.label }}
          </button>
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
          <model-form-uni-table-field
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
        :error-message="errors[field.name]"
      >
        <model-form-uni-widget
          :modelValue="values[field.name]"
          @update:modelValue="values[field.name] = $event"
          @blur:validate="formsItemRefs[field.name].onFieldChange($event)"
          v-model:error="errors[field.name]"
          :field="field"
        />
      </uni-forms-item>
    </template>
    <button type="primary" @click="submit" :disabled="loading">提交</button>
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
