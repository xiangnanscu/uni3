export const useBadgeNumber = async (opts) => {
  const {
    setFriendsApplyCount,
    setFriendsMessageCount,
    setSystemMessageCount
  } = useStore();
  const { friendsApplyCount, friendsMessageCount, systemMessageCount } =
    storeToRefs(useStore());
  const { friends_apply_count, friends_message_count, system_message_count } =
    await usePost(`/badge_number`, opts || {});
  if (typeof friends_apply_count == "number") {
    setFriendsApplyCount(friends_apply_count);
  }
  if (typeof friends_message_count == "number") {
    setFriendsMessageCount(friends_message_count);
  }
  if (typeof system_message_count == "number") {
    setSystemMessageCount(system_message_count);
  }
  const page = utils.getPage();
  if (utils.isTabbarPage("/" + page.route)) {
    const friendsMessageTotalCount =
      friendsApplyCount.value + friendsMessageCount.value;

    if (friendsMessageTotalCount) {
      uni.setTabBarBadge({
        index: 1,
        text: String(friendsMessageTotalCount)
      });
    } else {
      uni.removeTabBarBadge({
        index: 1
      });
    }
    if (systemMessageCount.value) {
      uni.setTabBarBadge({
        index: 3,
        text: String(system_message_count)
      });
    } else {
      uni.removeTabBarBadge({
        index: 3
      });
    }
  } else {
    console.log("not tabbar..");
  }

  return {
    friendsApplyCount,
    friendsMessageCount,
    systemMessageCount
  };
};
