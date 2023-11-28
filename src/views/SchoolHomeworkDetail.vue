<template>
  <page-layout v-if="record">
    <uni-card :isFull="true" :is-shadow="false" :border="false">
      <x-title :size-rate="1.2">{{ record.title }}</x-title>
      <fui-preview :previewData="previewData"></fui-preview>
      <x-album :urls="record.pics"></x-album>
      <x-text :text="record.content"></x-text>
      <template #actions>
        <x-button v-if="hasPermission" @click="onClickDelete" size="mini">删除</x-button>
      </template>
    </uni-card>
    <div style="height: 4em"></div>
    <uni-popup ref="deleteConfirmRef" type="dialog">
      <uni-popup-dialog
        mode="base"
        :title="`确定删除吗?`"
        confirmText="删除"
        :duration="1000"
        :before-close="true"
        @close="deleteConfirmRef.close()"
        @confirm="onDeleteConfirm"
      >
      </uni-popup-dialog>
    </uni-popup>
  </page-layout>
</template>

<script>
import MixinShare from "./MixinShare";

export default {
  mixins: [MixinShare],
  data() {
    return {
      modelName: "school_notice",
      disableJoinButton: false,
      record: null,
      roles: null,
    };
  },
  async onLoad(query) {
    this.query = query;
    await this.fetchData(query);
    this.roles = await helpers.getPassedRoles();
  },
  computed: {
    hasPermission() {
      return (
        this.roles.sys_admin ||
        this.roles.principal?.school_id === this.record.school_id ||
        this.roles.class_director?.class_id === this.record.class_id
      );
    },
    previewData() {
      const list = [
        {
          label: "创建时间",
          value: this.record.ctime.slice(0, 16),
        },
        {
          label: "学校",
          value: this.record.school_id__name,
        },
      ];
      if (this.record.class_id) {
        list.push({
          label: "班级",
          value: this.record.class_id__name,
        });
      }
      return {
        list,
      };
    },
  },
  methods: {
    onClickDelete() {
      this.$refs.deleteConfirmRef.open();
    },
    async onDeleteConfirm() {
      const { affected_rows } = await usePost(
        `/${this.modelName}/delete/${this.query.id}`,
      );
      if (affected_rows === 1) {
        this.$refs.deleteConfirmRef.close();
        uni.showToast({ title: "操作成功" });
        utils.redirect("SchoolHomework", 1000);
      } else {
        uni.showToast({ title: "删除失败" });
      }
    },
    async fetchData(query) {
      const record = await useGet(`/${this.modelName}/detail/${query.id}`);
      this.record = record;
    },
    async deleteRecordPop() {
      await usePost(`/${this.modelName}/delete/${this.query.id}`);
    },
  },
};
</script>

<style scoped>
.volplan-title {
  color: black;
  text-align: center;
  font-size: 150%;
  font-weight: bold;
  margin-bottom: 1em;
}
</style>
