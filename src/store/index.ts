import { ref, computed } from "vue";
import { defineStore } from "pinia";

export const useStore = defineStore("store", () => {
  const siderKeys = ref<string[]>([]);
  const headerLeftKeys = ref<string[]>([]);
  const headerRightKeys = ref<string[]>([]);
  const loading = ref(false);
  const disableLoading = ref(false)
  return {
    siderKeys,
    headerLeftKeys,
    headerRightKeys,
    loading,
    disableLoading,
  };
});
