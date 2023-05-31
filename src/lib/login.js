export default {
  data() {
    return {
      redirect: "",
      rules: {
        nickname: {
          rules: [
            {
              required: true,
              errorMessage: "姓名不能为空"
            }
          ]
        },
        avatar: {
          rules: [
            {
              validateFunction: function (rule, value, data, callback) {
                if (!value.url) {
                  callback("必须上传头像");
                }
                return true;
              }
            }
          ]
        }
      }
    };
  },
  onReady() {
    this.$refs.valiForm?.setRules(this.rules);
  },
  onLoad(query) {
    this.redirect = query.redirect ? decodeURIComponent(query.redirect) : "";
    // console.log("login.js onLoad query:", query);
  }
};
