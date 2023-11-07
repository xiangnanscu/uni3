import { usePost } from "@/composables/usePost";
import { useUser } from "@/composables/useUser";
import { useStore, useSession } from "@/store";

export async function getRoles(data) {
  return await usePost(`/role/get_roles`, data);
}

export async function getPassedRoles(data) {
  return await usePost(`/role/get_roles`, { ...data, status: "通过" });
}

export async function getWxUser() {
  const { code, errMsg } = await uni.login();
  if (errMsg !== "login:ok") {
    throw new Error(errMsg);
  }
  const user = await usePost("/wx_login", {
    code,
  });
  return user;
}

export const isLogin = () => {
  const sessionCookie = uni.getStorageSync("cookie_session");
  if (!sessionCookie) {
    return false;
  }
  const { session } = useSession();
  if (!session?.user?.id) {
    return false;
  }
  return true;
};

export async function autoLogin(force) {
  // #ifdef MP-WEIXIN
  const scene = wx?.getLaunchOptionsSync().scene;
  if (scene === 1154) {
    // 分享朋友圈点开的页面,无法正常登录,直接返回
    return;
  }
  if (force || !useUser().id) {
    const store = useStore();
    try {
      store.disableLoading = true;
      const user = await getWxUser();
      const { login } = useSession();
      login(user);
    } finally {
      store.disableLoading = false;
    }
  }
  // #endif
}

export class NeedLoginError extends Error {}

export function checkLogin() {
  const user = useUser();
  if (!user.id) {
    throw new NeedLoginError(`需要登录`);
  }
}
