// mouse.js
import { ref, onMounted, onUnmounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { notification } from "ant-design-vue";
import "ant-design-vue/lib/notification/style/css";
import { useMyStore } from "@/store/store";

export function useLeaderAssess() {
  const { loading } = storeToRefs(useMyStore());
  const { isWeixinBrowser } = useDisableWeixinShare();
  const route = useRoute();
  const router = useRouter();
  const params = route.params;
  const solution = ref(null);
  const org = ref(null);
  const persons = ref(null);
  const ready = ref(false);

  onMounted(async () => {
    if (!isWeixinBrowser.value && import.meta.env.PROD) {
      return;
    }
    const { data } = await Axios.get(
      `/leader_assess/encoded/${params.encoded}`
    );
    persons.value = data.persons;
    org.value = data.org;
    solution.value = data.solution;
    ready.value = true;
  });
  const columns = [
    {
      title: "测评项目",
      dataIndex: "测评项目",
    },
    {
      title: "评分",
      dataIndex: "评分",
      width: "60%",
    },
  ];
  const sliderFormaterZtpj = (value) => {
    if (!value) {
      return "";
    } else if (value >= 90) {
      return `优秀${value}`;
    } else if (value >= 80) {
      return `称职${value}`;
    } else if (value >= 70) {
      return `基本称职${value}`;
    } else {
      return `不称职${value}`;
    }
  };
  const sliderFormaterFxpj = (value) => {
    if (!value) {
      return "";
    } else if (value >= 90) {
      return `好${value}`;
    } else if (value >= 80) {
      return `较好${value}`;
    } else if (value >= 70) {
      return `一般${value}`;
    } else {
      return `差${value}`;
    }
  };
  const onFinishFailed = async ({
    errorFields: [
      {
        name: [label],
        errors: [error],
      },
    ],
  }) => {
    notification.error({ message: `${error}: ${label}` });
  };
  const isPersonDone = (personId) =>
    localStorage.getItem(`${params.encoded}/${personId}`);
  const setPersonDone = (personId) =>
    localStorage.setItem(`${params.encoded}/${personId}`, "done");
  const isOrgDone = () => localStorage.getItem(`${params.encoded}`);
  const setOrgDone = () => localStorage.setItem(`${params.encoded}`, "done");
  // expose managed state as return value
  return {
    isWeixinBrowser,
    setPersonDone,
    isPersonDone,
    setOrgDone,
    isOrgDone,
    onFinishFailed,
    columns,
    sliderFormaterZtpj,
    sliderFormaterFxpj,
    route,
    router,
    params,
    solution,
    org,
    persons,
    ready,
    loading,
    lowScore: 70,
  };
}
