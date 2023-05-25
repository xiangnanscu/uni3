<template>
  <page-layout>
    <!-- {{ JSON.stringify(profileData) }} -->
    <uni-forms
      ref="valiForm"
      validateTrigger="blur"
      :rules="rules"
      :model-value="profileData"
      label-position="top"
    >
      <uni-forms-item label="姓名" name="xm">
        <uni-easyinput
          v-model:value="profileData.xm"
          placeholder="请输入身份证上的姓名"
        />
      </uni-forms-item>
      <uni-forms-item label="身份证号" name="username">
        <uni-easyinput
          v-model:value="profileData.username"
          placeholder=" "
          type="idcard"
        />
      </uni-forms-item>
      <uni-forms-item label="手机号码" name="phone">
        <div class="flex-row">
          <div class="flex-item flex-phone">
            {{ profileData.phone || "" }}
          </div>
          <div class="flex-item">
            <button open-type="getPhoneNumber" @getphonenumber="getPhoneNumber">
              获取手机号
            </button>
          </div>
        </div>
        <!-- <uni-grid :column="2" :showBorder="false" :square="false">
            <uni-grid-item>
              <text class="phone-text">{{ profileData.phone }}</text>
            </uni-grid-item>
            <uni-grid-item>
              <button open-type="getPhoneNumber" @getphonenumber="getPhoneNumber">
                获取手机号
              </button>
            </uni-grid-item>
          </uni-grid> -->
        <!-- <uni-easyinput v-model="profileData.phone" placeholder="请输入手机号" /> -->
      </uni-forms-item>
    </uni-forms>
    <button type="primary" @click="submit('valiForm')">提交</button>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      profileData: {
        xm: "",
        username: "",
        phone: ""
      },
      rules: {
        xm: {
          rules: [
            {
              required: true,
              errorMessage: "姓名不能为空"
            }
          ]
        },
        phone: {
          rules: [
            {
              required: true,
              errorMessage: "手机号不能为空"
            },
            {
              pattern: "^\\d{11}$",
              errorMessage: "手机号必须为11位数字"
            },
            {
              validateFunction: function (rule, value, data, callback) {
                if (value.length < 2) {
                  callback("请至少勾选两个兴趣爱好");
                }
                return true;
              }
            }
          ]
        },
        username: {
          rules: [
            {
              required: true,
              errorMessage: "身份证号不能为空"
            },
            {
              pattern: "^\\d{17}[\\dXx]$",
              errorMessage: "身份号格式不正确"
            },
            {
              validateFunction: function (rule, value, data, callback) {
                if (value.length < 2) {
                  callback("格式不正确");
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
  async mounted() {
    const { data } = await this.$http.get("/usr/profile/my");
    this.profileData.xm = data.xm || "";
    this.profileData.phone = data.phone || "";
    this.profileData.username = data.username || "";
  },
  async onShow() {},
  onLoad() {
    console.log("profile onLoad");
  },
  methods: {
    async getPhoneNumber(e) {
      // 用户允许: e.detail = {errMsg: "getPhoneNumber:ok", code: "??" encryptedData: "??"iv: "??"}
      // 用户拒绝: e.detail = {errMsg: "getPhoneNumber:fail user deny"}
      const { code } = e.detail;
      if (code) {
        const { data } = await this.$http.post("/wx_phone", { code });
        this.profileData.phone = data.purePhoneNumber;
      }
    },
    async submit(ref) {
      await this.$refs[ref].validate();
      const id = this.user.id;
      if (id) {
        const user = {
          id,
          ...this.profileData
        };
        await this.$http.post("/update_profile", user);
        // this.$store.commit("login", { ...this.user, ...user });
        await this.tryGotoPage();
      }
    }
  }
};
</script>

<style>
.flex-row {
  display: flex;
  flex-direction: row;
  align-items: stretch;
  justify-content: space-between;
  flex-wrap: wrap;
}
.flex-itme {
  flex-grow: 1;
  flex: 1;
}
.flex-phone {
  display: flex;
  justify-content: center;
  flex-direction: column;
  font-size: 120%;
  padding-left: 6px;
  color: #666;
}
.content {
  padding: 15px;
}
.phone-text {
  color: #666;
  text-align: center;
  font-size: 120%;
  padding: 2px;
}
</style>
