import { ref } from "vue";

const loading = ref(false);
const disableLoading = ref(false);
const message = ref("");
const error = ref("");

export const useStore = () => {
  return {
    message,
    error,
    loading,
    disableLoading,
  };
};
