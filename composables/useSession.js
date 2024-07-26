import { reactive } from "vue";

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
  const cookies = document.cookie.split(";");
  for (let i = 0; i < cookies.length; i++) {
    const cookie = cookies[i];
    if (cookie.indexOf("session") !== -1) {
      document.cookie = cookie + "; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    }
  }
  // #endif
};

const refreshSession = () => {
  removeSession();
  return refreshSession();
};

const getSession = () => {
  const cookieSession = uni.getStorageSync("cookie_session");
  const storageSession = uni.getStorageSync("session");
  if (!cookieSession || !storageSession) {
    return refreshSession();
  }
  try {
    const session = JSON.parse(storageSession);
    if (typeof session !== "object" || typeof session.user !== "object") {
      return refreshSession();
    }
    if (!session.expire) {
      console.log("客户端未设置expire字段，SESSION过期");
      return refreshSession();
    }
    console.log(`客户端SESSION过期时间:${new Date(session.expire)}`);
    if (new Date().getTime() > session.expire) {
      console.log("客户端SESSION过期");
      return refreshSession();
    }
    if (typeof session.user !== "object" || !session.user.id) {
      console.log("没有从session找到登陆user");
      return refreshSession();
    }
    console.log(`session有效期内,还有${(session.expire - new Date().getTime()) / 1000 / 3600}小时`);
    return reactive(session);
  } catch (error) {
    return refreshSession();
  }
};

const session = getSession();

export const useSession = () => {
  return session;
};

export { getAnonymousSession, removeSession };
