import { ref, computed } from "vue";
import { defineStore } from "pinia";
import { useSession } from "@/store/session";

export const useMyStore = defineStore("store", () => {
  const { session, login, logout } = useSession();
  const siderKeys = ref<string[]>([]);
  const headerLeftKeys = ref<string[]>([]);
  const headerRightKeys = ref<string[]>([]);
  const loading = ref(false);
  return {
    session,
    login,
    logout,
    siderKeys,
    headerLeftKeys,
    headerRightKeys,
    loading,
  };
});
