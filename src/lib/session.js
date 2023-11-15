import { timeParser } from "@/lib/utils";

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
  });
const removeSession = () => {
  uni.removeStorageSync("session");
  uni.removeStorageSync("cookie_session");
};
const LIFETIME_SECONDS = timeParser(process.env.COOKIE_EXPIRES);
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
    if (new Date().getTime() > session.expire) {
      console.log("客户端SESSION过期");
      return getAnonymousSession();
    }
    if (typeof session.user !== "object" || !session.user.id) {
      console.log("没有从session找到登陆user");
      return getAnonymousSession();
    }
    console.log("session有效期内");
    return reactive(session);
  } catch (error) {
    return getAnonymousSession();
  }
};

export const useSession = defineStore("session", () => {
  console.log("useSession called");
  const session = getSession();
  if (!session.user.id) {
    removeSession();
  }
  function login(user) {
    Object.assign(session.user, user);
    session.expire = LIFETIME_SECONDS * 1000 + new Date().getTime();
    uni.setStorageSync("session", JSON.stringify(session));
  }
  function logout() {
    session.user = getAnonymousSession().user;
    removeSession();
  }
  return {
    session,
    login,
    logout,
  };
});