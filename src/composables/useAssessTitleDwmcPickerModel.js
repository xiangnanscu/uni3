// mouse.js
import { ref, onMounted } from "vue";
import Model from "@/model.mjs";

export function useAssessTitleDwmcPickerModel() {
  const PickerModel = ref(null);
  onMounted(async () => {
    PickerModel.value = await Model.createModelAsync({
      fields: [
        {
          name: "title",
          label: "考核方案",
          choicesUrl: "/leader_assess/choices?value=title",
        },
        {
          name: "dwmc",
          label: "单位名称",
          choicesUrl: "/org/choices?value=dwmc",
          autocomplete: false,
        },
      ],
    });
  });

  return {
    PickerModel,
    getInitialValues: () => ({
      title: PickerModel.value.fields.title.choices[0].value,
      dwmc: PickerModel.value.fields.dwmc.choices[0].value,
    }),
  };
}
