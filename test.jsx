fuck(1);
const Wigdet = ({ name, field, values }) => {
  const type = field.type;
  const tag = field.tag;
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
    <a-auto-complete
      onKeydown={disableEnterKeyDown} //防止按enter选择时表单提交
      v-model:value={values[name]}
      v-slots={{
        option: ({ label, hint }) => (
          <div style="display: flex; justify-content: space-between">
            {label}
            <span>{hint}</span>
          </div>
        )
      }}
      options={field.searchOptions}
      onSearch={onSearch}
    ></a-auto-complete>
  );
};
