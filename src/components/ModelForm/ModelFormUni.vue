
<script setup>
import { useRouter } from "vue-router";
import { Model } from "@/lib/model.mjs";
import { useStore } from "@/store";
import { onReady } from '@dcloudio/uni-app'

const deepcopy = (o) => JSON.parse(JSON.stringify(o));
const emit = defineEmits(['submit', 'successPost'])
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
  labelCol: { type: Number, default: 3 },
})
const router = useRouter();
const values = props.syncValues
  ? reactive(props.values)
  : reactive(deepcopy(props.values));
const errors = reactive(props.errors);
const { loading } = storeToRefs(useStore());
const formRef = ref();
const getUniRule = (field) => {
  return {
    validateFunction: function (rule, value, data, callback) {
      const name = field.name
      try {
        value = field.validate(value, data);
        if (value === undefined) {
          data[name] = "";
        } else {
          data[name] = value;
        }
        return true
      } catch (error) {
        callback(error.message)
      }
    }
  };
};
const fieldsArray = computed(() => props.model.names.map(name => props.model.fields[name]))
onBeforeMount(() => {
  Object.assign(values, props.model.toFormValue(values, props.model.names));
});
onMounted(() => {
  console.log("??????????")
  const rules = Object.fromEntries(fieldsArray.value.map(field => [field.name, { rules: [getUniRule(field)] }]))

  formRef.value.setRules(rules)

})

const formError = ref("");
const submiting = ref(false);
const clearBackendErrors = () => {
  formError.value = "";
  for (const key in errors) {
    errors[key] = "";
  }
};
const submit = async (ref) => {
  console.log({ formRef })
  const res = await formRef.value.validate()
  uni.showToast({
    title: `校验通过`
  })
}
const onFinish = async (values) => {
  clearBackendErrors();
  const data = props.model.toPostValue(values, props.model.names);
  emit("submit", data);
  if (!props.actionUrl) {
    return;
  }
  try {
    submiting.value = true;
    const response = await Http.post(props.actionUrl, data);
    emit("successPost", { data, response });
    if (props.successRoute) {
      router.push(
        typeof props.successRoute == "string"
          ? { path: props.successRoute }
          : props.successRoute
      );
    }
  } catch (error) {
    if (error.name == "AxiosError") {
      const { data, status } = error.response;
      if (status == 422) {
        errors[data.name] = data.message;
      } else {
        formError.value =
          typeof data == "object" ? JSON.stringify(data) : data;
      }
    } else {
      formError.value = error.message;
    }
  } finally {
    submiting.value = false;
  }
};

const onFinishFailed = ({ values, errorFields, outOfDate }) => {
  console.log("Failed:", { values, errorFields, outOfDate });
};

// { attrs, slots, emit, expose }
const disableEnterKeyDown = (e) => e.keyCode === 13 && e.preventDefault();
</script>
<template>
  <div>
    <uni-forms
      :ref="formRef"
      :modelValue="values"
    >
      <template
        v-for="(field, index) in fieldsArray"
        :key="index"
      >
        <uni-forms-item
          :label="field.label"
          :required="field.required"
          :name="field.name"
        >
          <uni-easyinput v-model="values[field.name]" />
        </uni-forms-item>
      </template>
      <button
        type="primary"
        @click="submit()"
        :disabled="loading"
      >提交</button>
    </uni-forms>
  </div>
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
