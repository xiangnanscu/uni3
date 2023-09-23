<template>
  <page-layout>
    <uni-card
      v-if="{{tableName}}"
      :title="{{tableName}}.title"
      :isFull="true"
      :is-shadow="false"
      :border="false"
      :extra="utils.fromNow({{tableName}}.ctime)"
    >
      <text class="uni-body">\{{ {{tableName}}.content }}</text>
      <template v-slot:actions>
        <u-button type="primary"></u-button>
      </template>
    </uni-card>
  </page-layout>
</template>

<script>
export default {
  data() {
    return {
      query: {},
      {{tableName}}: null,
    };
  },
  async onLoad(query) {
    this.query = query
    await this.fetchData(query)
  },
  methods: {
    async fetchData(query) {
      const { data: {{tableName}} } = await Http.get(
        `/{{tableName}}/detail/${query.id}`
      );
      this.{{tableName}} = {{tableName}};
    },
  },
};
</script>

<style scoped></style>
