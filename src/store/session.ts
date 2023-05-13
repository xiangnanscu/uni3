import { useCookies } from "@vueuse/integrations/useCookies";
const cookies = useCookies();
const sessionCookie = cookies.get("session");
const sessionStorage = localStorage.getItem("session");
// console.log({ sessionCookie, sessionStorage });

const getAnonymousSession = () =>
  reactive({
    user: { nickname: "游客", id: null, permission: 0, openid: "", avatar: "" },
  });
const getSession = () => {
  if (!sessionCookie || !sessionStorage) {
    return getAnonymousSession();
  }
  const session = JSON.parse(sessionStorage);
  if (!session || !session.user || session.user.id === 0) {
    return getAnonymousSession();
  }
  return reactive(session);
};
interface SessionUser {
  id: number;
  username: string;
  nickname: string;
  permission: number;
  openid: string;
  avatar: string;
}
export const useSession = defineStore("session", () => {
  const session = getSession();
  function login(user: SessionUser) {
    Object.assign(session.user, user);
    localStorage.setItem("session", JSON.stringify(session));
  }
  function logout() {
    Object.assign(session.user, getAnonymousSession().user);
    localStorage.removeItem("session");
    cookies.remove("session");
  }
  return {
    session,
    login,
    logout,
  };
});
