<script lang="jsx">
import { useRouter } from "vue-router";
import { Model } from "@/lib/model.mjs";
import { Http, Alioss } from "@/globals";
import { useStore } from "@/store";

const deepcopy = (o) => JSON.parse(JSON.stringify(o));
export default {
  name: "ModelFormUni",
  inheritAttrs: true,
  emits: ["submit", "successPost"],
  props: {
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
  },
  setup(props, { attrs, slots, emit, expose }) {
    const router = useRouter();
    const model = ref(null);
    const values = props.syncValues
      ? reactive(props.values)
      : reactive(deepcopy(props.values));
    const errors = reactive(props.errors);
    const { loading } = storeToRefs(useStore());
    onBeforeMount(async () => {
      if (!props.model.__isModelClass__) {
        model.value = await Model.createModelAsync({
          disableAutoPrimaryKey: true,
          ...props.model,
        });
      } else {
        model.value = props.model;
      }
      Object.assign(values, model.value.toFormValue(values, model.value.names));
    });
    const formRef = ref();
    const formError = ref("");
    const submiting = ref(false);
    const clearBackendErrors = () => {
      formError.value = "";
      for (const key in errors) {
        errors[key] = "";
      }
    };
    const onFinish = async (values) => {
      clearBackendErrors();
      const data = model.value.toPostValue(values, model.value.names);
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
    const getUniRule = (field) => {
      const rule = {
        whitespace: true,
        trigger: props.trigger,
      };
      rule.validator = async (_rule, value) => {
        try {
          return Promise.resolve(field.validate(value));
        } catch (error) {
          return Promise.reject(error);
        }
      };
      // rule.validator = (_rule, value) => {
      //   field.validate(value);
      // };
      return rule;
    };
    // { attrs, slots, emit, expose }
    const disableEnterKeyDown = (e) => e.keyCode === 13 && e.preventDefault();
    const Wigdet = ({ name, field, values }) => {
      const type = field.type;
      const tag = field.tag;
      if (field.autocomplete) {
        const onSearch = (text) => {
          if (!text) {
            return [];
          }
          const matchRule = new RegExp(text.split("").join(".*"));
          field.searchOptions = field.choices.filter((e) => {
            // 暂时只针对字符串过滤
            if (typeof e.value == "string") {
              return e.value.includes(text) || matchRule.test(e.value);
            } else {
              return true;
            }
          });
        };
        return (
          <uni-auto-complete
            onKeydown={disableEnterKeyDown} //防止按enter选择时表单提交
            v-model:value={values[name]}
            v-slots={{
              option: ({ label, hint }) => (
                <div style="display: flex; justify-content: space-between">
                  {label}
                  <span>{hint}</span>
                </div>
              ),
            }}
            options={field.searchOptions}
            onSearch={onSearch}
          ></uni-auto-complete>
        );
      } else if (field.choices) {
        if (field.tag == "radio") {
          return (
            <uni-radio-group v-model:value={values[name]}>
              {field.choices.map((c) => (
                <uni-radio-button value={c.value}>{c.label}</uni-radio-button>
              ))}
            </uni-radio-group>
          );
        } else {
          return (
            <uni-select v-model:value={values[name]}>
              {field.choices.map((c) => (
                <uni-select-option value={c.value}>{c.label}</uni-select-option>
              ))}
            </uni-select>
          );
        }
      } else if (tag == "slider") {
        return (
          <uni-slider
            v-model:value={values[name]}
            min={field.min}
            max={field.max}
            step={field.step}
            tooltipVisible={field.tooltipVisible}
          ></uni-slider>
        );
      } else if (type.startsWith("alioss")) {
        // console.log("alioss value:", values[name]);
        const commonProps = {
          fileList: values[name],
          "onUpdate:fileList": (value) => {
            values[name] = value;
          },
          data: Alioss.makeAntdDataCallback(field),
          action: field.uploadUrl || process.env.ALIOSS_URL,
          multiple: field.multiple ?? false,
        };
        if (type == "aliossImage" || type == "alioss") {
          commonProps.maxCount = 1;
        }
        switch (type) {
          case "aliossImage":
          case "aliossImageList":
            return (
              <uni-upload
                {...commonProps}
                list-type={field.listType || "picture-card"}
              >
                <div>
                  <PlusOutlined />
                  <div>{field.buttonText || "上传图片"}</div>
                </div>
              </uni-upload>
            );
          default:
            return (
              <uni-upload {...commonProps}>
                <uni-button>
                  <UploadOutlined></UploadOutlined>
                  {field.buttonText || "上传文件"}
                </uni-button>
              </uni-upload>
            );
        }
      } else if (type == "boolean") {
        return (
          <uni-switch
            v-model:checked={values[name]}
            checked-children="开"
            un-checked-children="关"
          />
        );
      } else if (type == "date") {
        return (
          <uni-date-picker
            v-model:value={values[name]}
            value-format={field.valueFormat || "YYYY-MM-DD"}
          />
        );
      } else if (type == "yearMonth") {
        return (
          <uni-date-picker
            v-model:value={values[name]}
            format={"YYYY.MM"}
            value-format={"YYYY.MM"}
            picker="month"
          />
        );
      } else if (type == "year") {
        return (
          <uni-date-picker
            v-model:value={values[name]}
            format={"YYYY"}
            value-format={"YYYY"}
            picker="year"
          />
        );
      } else if (type == "datetime") {
        const change = (date, datetime) => {
          values[name] = datetime;
        };
        // 如果设置v-model:value={values[name]},time部分始终是00:00:00
        return (
          <uni-date-picker
            show-time={{ format: field.timeFormat || "HH:mm" }}
            onChange={change}
            value-format={field.valueFormat || "YYYY-MM-DD"}
          />
        );
      } else if (type == "password") {
        // https://github.com/yiminghe/async-validator#type
        return (
          <uni-input-password
            v-model:value={values[name]}
            onKeydown={disableEnterKeyDown}
          ></uni-input-password>
        );
      } else if (type == "float" || type == "integer") {
        return (
          <uni-input-number
            v-model:value={values[name]}
            onKeydown={disableEnterKeyDown}
          ></uni-input-number>
        );
      } else {
        return (
          <uni-input
            v-model:value={values[name]}
            onKeydown={disableEnterKeyDown}
          ></uni-input>
        );
      }
    };
    return () => {
      if (!model.value) {
        return;
      }
      return (
        <uni-form
          {...formItemLayout.value}
          ref={formRef}
          layout={props.layout}
          model={values}
          onFinish={onFinish}
          onFinishFailed={onFinishFailed}
        >
          {formError.value && (
            <uni-alert
              message="发生错误"
              description={formError.value}
              type="error"
              show-icon
            />
          )}
          {model.value.names.map((name) => {
            const field = model.value.fields[name];
            if (field.type === "array") {
              const arr = values[name];
              return (
                <>
                  {arr.map((value, index) => (
                    <uni-form-item
                      key={index}
                      label={index === 0 ? field.label : ""}
                      name={[name, index]}
                      {...(index === 0 ? {} : buttonItemLayout.value)}
                      extra={field.hint}
                      style="margin-bottom: 8px"
                    >
                      {/* <uni-input
                        style="width: 80%; margin-right: 8px"
                        v-model:value={arr[index]}
                      ></uni-input> */}
                      <Wigdet
                        style="width: 80%; margin-right: 8px"
                        field={{ ...field, type: field.arrayType || "string" }}
                        name={[index]}
                        values={arr}
                      ></Wigdet>
                      {arr.length > 0 && (
                        <MinusCircleOutlined
                          class="dynamic-delete-button"
                          disabled={arr === 1}
                          onClick={() => {
                            arr.splice(index, 1);
                          }}
                        />
                      )}
                    </uni-form-item>
                  ))}
                  <uni-form-item
                    {...(arr.length === 0
                      ? { label: field.label }
                      : buttonItemLayout.value)}
                  >
                    <uni-button
                      type="dashed"
                      style="width: 80%"
                      onClick={() => {
                        arr.push(field.getDefault());
                      }}
                    >
                      <PlusOutlined />
                      添加
                    </uni-button>
                  </uni-form-item>
                </>
              );
            } else if (field.type == "table") {
              return (
                <uni-form-item
                  name={field.name}
                  label={field.label}
                  extra={field.hint}
                >
                  <model-form-table-field
                    model={field.model}
                    rows={values[name]}
                    onUploadRows={(rows) => {
                      values[name] = rows;
                    }}
                    onDeleteRow={(index) => {
                      values[name].splice(index, 1);
                    }}
                  ></model-form-table-field>
                  {errors[name] && (
                    <uni-alert message={errors[name]} type="error" show-icon />
                  )}
                </uni-form-item>
              );
            } else {
              return (
                <uni-form-item
                  name={name}
                  label={field.label}
                  rules={[getUniRule(field)]}
                  extra={field.hint}
                  style={props.layout == "inline" ? { "min-width": "20%" } : {}}
                >
                  <Wigdet field={field} name={name} values={values}></Wigdet>
                  {errors[name] && (
                    <uni-alert message={errors[name]} type="error" show-icon />
                  )}
                </uni-form-item>
              );
            }
          })}
          {!props.hideSubmitButton && (
            <uni-form-item {...buttonItemLayout.value}>
              <uni-button
                disabled={submiting.value}
                type="primary"
                html-type="submit"
                loading={loading.value}
              >
                {props.buttonText || "提交"}
              </uni-button>
            </uni-form-item>
          )}
        </uni-form>
      );
    };
  },
};
</script>

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
