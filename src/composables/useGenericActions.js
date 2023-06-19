export function useGenericActions({ target_model, target_id }) {
  const { session } = useSession();
  const actionsReady = ref(false);
  const favStatus = ref(false);
  const shareStatus = ref(false);
  const likeStatus = ref(false);
  const actionsMap = {
    分享: shareStatus,
    收藏: favStatus,
    点赞: likeStatus
  };
  onMounted(async () => {
    console.log("useGenericActions onMounted");
    const { data: actions } = await Http.post(`/actions/stat`, {
      target_model,
      target_id
    });
    for (const [actionName, actionRef] of Object.entries(actionsMap)) {
      const existed = actions.find((e) => e.type === actionName);
      if (existed) {
        actionRef.value = true;
      }
    }
    actionsReady.value = true;
  });
  const postAction = async ({
    target_model,
    target_id,
    usr_id,
    type,
    enabled
  }) => {
    return await Http.post(`/actions/get_or_create`, {
      target_model,
      target_id,
      usr_id,
      type,
      enabled
    });
  };
  const onLike = async () => {
    const actionValue = !likeStatus.value;
    const action = await postAction({
      target_model,
      target_id,
      usr_id: session.user.id,
      type: "点赞",
      enabled: actionValue
    });
    likeStatus.value = actionValue;
    uni.showToast({ title: `${actionValue ? "已" : "已取消"}点赞` });
    return actionValue;
  };
  const onFav = async () => {
    const actionValue = !favStatus.value;
    const action = await postAction({
      target_model,
      target_id,
      usr_id: session.user.id,
      type: "收藏",
      enabled: actionValue
    });
    favStatus.value = actionValue;
    uni.showToast({ title: `${actionValue ? "已" : "已取消"}收藏` });
    return actionValue;
  };
  const onShare = async () => {
    const actionValue = !shareStatus.value;
    const action = await postAction({
      target_model,
      target_id,
      usr_id: session.user.id,
      type: "分享",
      enabled: actionValue
    });
    shareStatus.value = actionValue;
    return actionValue;
  };
  return {
    actionsReady,
    actionsMap,
    favStatus,
    shareStatus,
    likeStatus,
    onLike,
    onFav,
    onShare
  };
}
