import { ref, computed } from "vue";
import { defineStore } from "pinia";
export { useSession } from "@/lib/session";

export const useStore = defineStore("store", () => {
  const siderKeys = ref<string[]>([]);
  const headerLeftKeys = ref<string[]>([]);
  const headerRightKeys = ref<string[]>([]);
  const loading = ref(false);
  const disableLoading = ref(false);
  const message = ref("");
  const error = ref("");
  const friendsApplyCount = ref(0);
  const friendsMessageCount = ref(0);
  const systemMessageCount = ref(0);
  const setFriendsApplyCount = (n) => {
    friendsApplyCount.value = n;
  };
  const setFriendsMessageCount = (n) => {
    friendsMessageCount.value = n;
  };
  const setSystemMessageCount = (n) => {
    systemMessageCount.value = n;
  };
  return {
    setFriendsApplyCount,
    setFriendsMessageCount,
    setSystemMessageCount,
    friendsApplyCount,
    friendsMessageCount,
    systemMessageCount,
    message,
    error,
    siderKeys,
    headerLeftKeys,
    headerRightKeys,
    loading,
    disableLoading,
  };
});
