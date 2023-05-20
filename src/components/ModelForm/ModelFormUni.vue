<script setup>
import { useRouter } from "vue-router";
import { useStore } from "@/store";
import { onReady } from "@dcloudio/uni-app";

const emit = defineEmits(["submit", "successPost"]);
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
const deepcopy = (o) => JSON.parse(JSON.stringify(o));
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
      const name = field.name;
      try {
        value = field.validate(value, data);
        if (value === undefined) {
          data[name] = "";
        } else {
          data[name] = value;
        }
        return true;
      } catch (error) {
        callback(error.message);
      }
    }
  };
};
const fieldsArray = computed(() =>
  props.model.names.map((name) => props.model.fields[name])
);
onBeforeMount(() => {
  Object.assign(values, props.model.toFormValue(values, props.model.names));
});
onMounted(() => {
  const rules = Object.fromEntries(
    fieldsArray.value.map((field) => [
      field.name,
      {
        rules: [
          { required: field.required, errorMessage: `必须填写${field.label}` },
          getUniRule(field)
        ]
      }
    ])
  );
  formRef.value.setRules(rules);
});

const formError = ref("");
const submiting = ref(false);
const clearBackendErrors = () => {
  formError.value = "";
  for (const key in errors) {
    errors[key] = "";
  }
};
const submit = async (ref) => {
  try {
    formRef.value.clearValidate();
    clearBackendErrors();
    const cleanedData = await formRef.value.validate();
    const data = props.model.toPostValue(cleanedData, props.model.names);
    log(data);
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
  } catch (error) {
    console.log(error);
  }
};

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
const getUniMediatype = (field) =>
  field.mediaType == "video"
    ? "video"
    : field.type.includes("Image")
    ? "image"
    : "all";
const autocompletePopupRefs = {};
const filePickerRefs = {};
const fuiFileStatus = {};
const filePickerSelectHanlder = {};
for (const field of fieldsArray.value) {
  if (field.autocomplete) {
    autocompletePopupRefs[field.name] = ref(null);
  } else if (field.type.startsWith("alioss")) {
    filePickerRefs[field.name] = ref(null);
    fuiFileStatus[field.name] = "";
    filePickerSelectHanlder[field.name] = async ({
      tempFiles,
      tempFilePaths
    }) => {
      const files = filePickerRefs[field.name].files;
      for (const file of tempFiles) {
        const uniFileIndex = files.findIndex((f) => f.uuid == file.uuid);
        if (file.size > field.size) {
          errors[field.name] = `文件过大(当前${Math.round(
            file.size / 1024 / 1024
          )}MB,上限${field.sizeArg})`;
          files.splice(uniFileIndex, 1);
          continue;
        }
        try {
          const url = await Alioss.uploadUni({
            file,
            size: field.size,
            prefix: "img"
          });
          values[field.name].push({ ossUrl: url });
        } catch (error) {
          errors[field.name] = error.message || "上传出错";
          // files[uniFileIndex].errMsg = "上传出错";
          // files[uniFileIndex].status = "error";
          files.splice(uniFileIndex, 1);
        }
      }
    };
  }
}
const fileValues = ref({});
// 以下三个都是uniCloud专用的
const filePickerFail = ({ tempFiles, tempFilePaths }) => {};
const filePickerSuccess = ({ tempFiles, tempFilePaths }) => {};
const filePickerProgress = ({
  progress,
  index,
  tempFile,
  tempFiles,
  tempFilePaths
}) => {};
const formsItemRefs = Object.fromEntries(
  fieldsArray.value.map((f) => [f.name, ref(null)])
);
const log = console.log;
</script>
<template>
  <div>
    <uni-forms
      ref="formRef"
      :model="values"
      label-width="5em"
      label-align="right"
    >
      <button type="primary" @click="submit()" :disabled="loading">提交</button>
      <template v-for="(field, index) in fieldsArray" :key="index">
        <uni-forms-item
          :ref="(el) => (formsItemRefs[field.name] = el)"
          :label="field.label"
          :required="field.required"
          :name="field.name"
          :error-message="errors[field.name]"
        >
          <uni-easyinput
            v-if="field.autocomplete"
            v-model="values[field.name]"
            :disabled="field.disabled"
            :placeholder="field.hint"
            @focus="autocompletePopupRefs[field.name].open()"
            suffixIcon="forward"
          />
          <uni-easyinput
            v-else-if="field.type == 'password'"
            type="password"
            v-model="values[field.name]"
            :disabled="field.disabled"
            :placeholder="field.hint"
          ></uni-easyinput>
          <template v-else-if="field.choices">
            <uni-data-checkbox
              v-if="field.tag == 'radio'"
              :disabled="field.disabled"
              mode="tag"
              v-model="values[field.name]"
              :localdata="field.choices"
            ></uni-data-checkbox>
            <uni-data-select
              v-else
              :disabled="field.disabled"
              v-model="values[field.name]"
              :localdata="field.choices"
            ></uni-data-select>
          </template>
          <slider
            v-else-if="field.tag == 'slider'"
            show-value
            :disabled="field.disabled"
            @change="values[field.name] = $event.detail.value"
            :value="values[field.name]"
            :min="field.min"
            :max="field.max"
          />
          <uni-datetime-picker
            v-else-if="field.type == 'date'"
            type="date"
            :clear-icon="false"
            v-model="values[field.name]"
            :disabled="field.disabled"
            :placeholder="field.hint"
          />
          <uni-datetime-picker
            v-else-if="field.type == 'datetime'"
            type="datetime"
            :clear-icon="false"
            v-model="values[field.name]"
            :disabled="field.disabled"
            :placeholder="field.hint"
          />
          <picker
            v-else-if="field.type == 'yearMonth'"
            mode="date"
            fields="month"
            :value="values[field.name]"
            @change="values[field.name] = $event.detail.value"
          >
            <uni-easyinput
              v-model="values[field.name]"
              :disabled="field.disabled"
              :placeholder="field.hint"
              suffixIcon="forward"
            />
          </picker>
          <picker
            v-else-if="field.type == 'year'"
            mode="date"
            fields="year"
            :value="values[field.name]"
            @change="values[field.name] = $event.detail.value"
          >
            <uni-easyinput
              v-model="values[field.name]"
              :disabled="field.disabled"
              :placeholder="field.hint"
              suffixIcon="forward"
            />
          </picker>
          <uni-file-picker
            v-else-if="field.type.startsWith('alioss')"
            v-model="fileValues[field.name]"
            :file-mediatype="getUniMediatype(field)"
            :limit="field.type.endsWith('List') ? field.limit || 9 : 1"
            :ref="(el) => (filePickerRefs[field.name] = el)"
            :disabled="field.disabled"
            :title="' '"
            mode="grid"
            :disable-preview="true"
            return-type="array"
            @select="filePickerSelectHanlder[field.name]"
            @success="filePickerSuccess"
            @progress="filePickerProgress"
            @fail="filePickerFail"
          />
          <uni-easyinput
            v-else-if="field.type == 'integer'"
            v-model="values[field.name]"
            :disabled="field.disabled"
            :placeholder="field.hint"
            type="number"
          />
          <uni-easyinput
            v-else-if="field.type == 'float'"
            v-model="values[field.name]"
            :disabled="field.disabled"
            :placeholder="field.hint"
            type="digit"
          />
          <uni-easyinput
            v-else
            v-model="values[field.name]"
            :disabled="field.disabled"
            :placeholder="field.hint"
          />
        </uni-forms-item>
        <uni-popup
          v-if="field.autocomplete"
          :ref="(el) => (autocompletePopupRefs[field.name] = el)"
          type="bottom"
          background-color="#fff"
        >
          <uni-section :title="field.label" padding>
            <uni-easyinput
              v-model="values[field.name]"
              placeholder="请输入姓名关键字"
              focus
            />
            <scroll-view :scroll-y="true" style="height: 31em">
              <uni-list>
                <uni-list-item
                  v-for="(c, i) in values[field.name]
                    ? field.choices.filter((e) =>
                        e.value.includes(values[field.name])
                      )
                    : []"
                  clickable
                  @click="
                    values[field.name] = c.value;
                    autocompletePopupRefs[field.name].close();
                  "
                  :key="i"
                  :title="c.value"
                  :rightText="c.hint"
                />
              </uni-list>
            </scroll-view>
          </uni-section>
        </uni-popup>
      </template>
      <button type="primary" @click="submit" :disabled="loading">提交</button>
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
