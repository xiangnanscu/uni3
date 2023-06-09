<template>
  <page-layout>
    <uni-forms
      ref="valiForm"
      :rules="rules"
      :model="profileData"
      label-position="left"
    >
      <uni-forms-item label="头像" name="avatar" :error-message="errors.avatar">
        <!-- #ifdef H5 -->
        <uni-file-picker
          ref="filePickerRef"
          :model-value="profileData.avatar"
          file-mediatype="image"
          :limit="1"
          :title="' '"
          mode="grid"
          :disable-preview="true"
          return-type="object"
          @select="filePickerSelectHanlder"
        />
        <!-- #endif -->

        <!-- #ifdef MP-WEIXIN -->
        <x-picker
          :size="avatarSizeArg"
          v-model="profileData.avatar"
          v-model:error="errors.avatar"
        />
        <!-- #endif -->
      </uni-forms-item>
      <uni-forms-item label="昵称" name="nickname">
        <uni-easyinput
          v-model="profileData.nickname"
          placeholder="请输入昵称"
          type="nickname"
        />
      </uni-forms-item>
      <uni-forms-item label="简介" name="intro">
        <uni-easyinput
          v-model="profileData.intro"
          placeholder="请输入简介"
          autoHeight
          type="textarea"
        />
      </uni-forms-item>
      <button type="primary" @click="submit">提交</button>
    </uni-forms>
  </page-layout>
</template>

<script>
import { parseSize } from "@/lib/utils.mjs";

const avatarSizeArg = process.env.ALIOSS_AVATAR_SIZE || "2M";
const avatarSize = parseSize(avatarSizeArg);

const getAvatarObject = (url) => {
  const [_, name, extname] = url.match(/\/([^/]+)\.([^/]+)$/);
  return {
    name: name + "." + extname,
    extname,
    url
  };
};
export default {
  data() {
    return {
      errors: {},
      avatarSizeArg,
      profileData: {
        intro: "",
        nickname: "",
        avatar: {
          name: "",
          extname: "",
          url: "",
          errMsg: ""
        }
      },
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
  },
  async mounted() {
    const { data } = await Http.get("/usr/profile/my");
    this.profileData.intro = data.intro;
    this.profileData.avatar = getAvatarObject(data.avatar);
    this.profileData.nickname = data.nickname;
  },

  methods: {
    async filePickerSelectHanlder({ tempFiles, tempFilePaths }) {
      const files = this.$refs.filePickerRef.files;
      for (const file of tempFiles) {
        const uniFileIndex = files.findIndex((f) => f.uuid == file.uuid);
        if (file.size > avatarSize) {
          this.errors.avatar = `文件过大(当前${Math.round(
            file.size / 1024 / 1024
          )}MB,上限${avatarSizeArg})`;
          files.splice(uniFileIndex, 1);
          continue;
        }
        try {
          const url = await Alioss.uploadUni({
            file,
            size: avatarSize,
            prefix: "img"
          });
          this.profileData.avatar.url = url;
        } catch (error) {
          console.error(error);
          this.errors.avatar = error.message || "上传出错";
          files.splice(uniFileIndex, 1);
        }
      }
    },
    async submit() {
      await this.$refs.valiForm.validate();
      const id = this.user.id;
      if (id) {
        const user = {
          id,
          intro: this.profileData.intro,
          nickname: this.profileData.nickname,
          avatar: this.profileData.avatar.url
        };
        await Http.post("/update_profile", user);
        const { login } = useSession();
        login({
          ...this.user,
          ...user
        });
        await utils.gotoPage({
          url: this.redirect || "/pages/tabbar/ProfileMy"
        });
      }
    }
  }
};
</script>
