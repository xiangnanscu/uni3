export function useGenericActions({ targetModel, target }) {
  const { session } = useSession();
  const actionsReady = ref(false);
  const favStatus = ref(false);
  const shareStatus = ref(false);
  const likeStatus = ref(false);
  const shareCount = ref(0);
  const likeCount = ref(0);
  const favCount = ref(0);
  const target_id = target.id;
  const target_model = targetModel;
  const actionsMap = {
    分享: shareStatus,
    收藏: favStatus,
    点赞: likeStatus
  };
  onMounted(async () => {
    if (!session.user.id) {
      return;
    }
    const actions = await usePost(`/actions/stat`, {
      target_model,
      target_id
    });
    for (const [actionName, actionRef] of Object.entries(actionsMap)) {
      const existed = actions.find((e) => e.type === actionName);
      if (existed) {
        actionRef.value = true;
      }
    }
    const actionsCount = await usePost(`/actions/stat_count`, {
      target_model,
      target_id
    });
    for (const e of actionsCount) {
      if (e.type == "点赞") {
        likeCount.value = e.count;
      } else if (e.type == "收藏") {
        favCount.value = e.count;
      } else if (e.type == "分享") {
        shareCount.value = e.count;
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
    if (actionValue && target.creator && target.creator !== session.user.id) {
      await usePost("/system_message/create", {
        type: "thumb_up",
        target_usr: target.creator,
        content: {
          target_model,
          target_id,
          target_digest: utils.textDigest(target.title, 31),
          creator__avatar: session.user.avatar,
          creator__nickname: session.user.nickname
        }
      });
    }
    likeStatus.value = actionValue;
    likeCount.value += actionValue ? 1 : -1;
    uni.showToast({
      icon: "none",
      title: `${actionValue ? "已" : "已取消"}点赞`
    });
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
    favCount.value += actionValue ? 1 : -1;
    uni.showToast({
      icon: "none",
      title: `${actionValue ? "已" : "已取消"}收藏`
    });
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
    shareCount,
    favCount,
    likeCount,
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
