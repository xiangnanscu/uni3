import { timeParser } from "@/lib/utils";
import { useSession, getAnonymousSession, removeSession } from "@/store/useSession";

const LIFETIME_SECONDS = timeParser(process.env.COOKIE_EXPIRES);

export const useAuth = defineStore("auth", () => {
  console.log("useAuth called");
  const session = useSession();
  function login({ user, roles }) {
    if (user) Object.assign(session.user, user);
    if (roles) Object.assign(session.roles, roles);
    session.expire = LIFETIME_SECONDS * 1000 + new Date().getTime();
    const sessionStr = JSON.stringify({
      user: session.user,
      roles: session.roles,
      expire: session.expire,
    });
    log("encode session", sessionStr);
    uni.setStorageSync("session", sessionStr);
    // throw new Error("登录成功");
  }
  function logout() {
    session.user = getAnonymousSession().user;
    session.roles = {};
    removeSession();
  }
  return {
    session,
    login,
    logout,
  };
});
