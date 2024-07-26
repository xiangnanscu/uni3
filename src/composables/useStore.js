import { ref } from "vue";

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

export const useStore = () => {
  return {
    setFriendsApplyCount,
    setFriendsMessageCount,
    setSystemMessageCount,
    friendsApplyCount,
    friendsMessageCount,
    systemMessageCount,
    message,
    error,
    loading,
    disableLoading,
  };
};
