interface SessionUser {
  id: number;
  username: string;
  nickname: string;
  xm: string;
  permission: number;
  openid: string;
  avatar: string;
}

const getAnonymousSession = () =>
  reactive({
    user: {
      nickname: "游客",
      username: "",
      xm: "",
      id: null,
      permission: 0,
      openid: "",
      avatar: ""
    }
  });

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
    return reactive(session);
  } catch (error) {
    return getAnonymousSession();
  }
};

export const useSession = defineStore("session", () => {
  console.log("useSession called");
  const session = getSession();
  const { tryRedirect } = useRedirect({ decode: true });
  function login(user: SessionUser) {
    // console.log("login user", JSON.stringify(user));
    Object.assign(session.user, user);
    uni.setStorageSync("session", JSON.stringify(session));
  }
  async function loginWithRedirect(user: SessionUser) {
    login(user);
    await tryRedirect();
  }
  function logout() {
    Object.assign(session.user, getAnonymousSession().user);
    uni.removeStorageSync("session");
    uni.removeStorageSync("cookie_session");
  }
  return {
    session,
    login,
    loginWithRedirect,
    logout
  };
});
