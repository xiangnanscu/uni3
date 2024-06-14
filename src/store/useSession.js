// interface SessionUser {
//   id: number;
//   username: string;
//   nickname: string;
//   xm: string;
//   permission: number;
//   openid: string;
//   avatar: string;
// }

const getAnonymousSession = () =>
  reactive({
    user: {
      nickname: "游客",
      username: "",
      xm: "",
      id: null,
      permission: 0,
      openid: "",
      avatar: "",
    },
    roles: {},
  });

const removeSession = () => {
  uni.removeStorageSync("session");
  uni.removeStorageSync("cookie_session");
  // #ifdef H5
  // 获取当前所有的cookie
  var cookies = document.cookie.split(";");

  // 遍历所有的cookie
  for (var i = 0; i < cookies.length; i++) {
    var cookie = cookies[i];

    // 在每个cookie中查找名为'session'的cookie
    if (cookie.indexOf("session") !== -1) {
      // 将名为'session'的cookie的过期日期设置为过去的时间，以将其删除
      document.cookie = cookie + "; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    }
  }

  // #endif
};
const getSession = () => {
  const cookieSession = uni.getStorageSync("cookie_session");
  const storageSession = uni.getStorageSync("session");
  if (!cookieSession || !storageSession) {
    return getAnonymousSession();
  }
  try {
    const session = JSON.parse(storageSession);
    if (typeof session !== "object" || typeof session.user !== "object") {
      return getAnonymousSession();
    }
    if (!session.expire) {
      console.log("客户端未设置expire字段，SESSION过期");
      return getAnonymousSession();
    }
    console.log(`客户端SESSION过期时间:${new Date(session.expire)}`);
    if (new Date().getTime() > session.expire) {
      console.log("客户端SESSION过期");
      return getAnonymousSession();
    }
    if (typeof session.user !== "object" || !session.user.id) {
      console.log("没有从session找到登陆user");
      return getAnonymousSession();
    }
    console.log(`session有效期内,还有${(session.expire - new Date().getTime()) / 1000 / 3600}小时`);
    return reactive(session);
  } catch (error) {
    removeSession();
    return getAnonymousSession();
  }
};
const session = getSession();
export const useSession = defineStore("session", () => {
  console.log("useSession called");
  if (!session.user.id) {
    removeSession();
  }
  return session;
});

export { getAnonymousSession, removeSession };
