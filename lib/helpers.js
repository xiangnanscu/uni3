import { usePost } from "~/lib/Http";
import { useUser } from "~/composables/useAuth";
import { useStore } from "~/composables/useStore";
import { useSession } from "~/composables/useSession";
import { getFullPath } from "~/lib/utils";

export async function getRoles(data) {
  return await usePost(`/role/get_roles`, data);
}

export async function getPassedRoles() {
  return await usePost(`/role/get_roles`, { status: "通过" });
}

export async function getWxUser() {
  const { code, errMsg } = await uni.login();
  if (errMsg !== "login:ok") {
    throw new Error(errMsg);
  }
  const { user, roles } = await usePost("/wx_login", {
    code,
  });
  return { user, roles };
}

export const isLogin = () => {
  const sessionCookie = uni.getStorageSync("cookie_session");
  if (!sessionCookie) {
    return false;
  }
  const session = useSession();
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
      const { user, roles } = await getWxUser();
      const { login } = useAuth();
      login({ user, roles });
    } finally {
      store.disableLoading = false;
    }
    return useUser();
  } else {
    return useUser();
  }
  // #endif
}

export class NeedLoginError extends Error {}
export class NeedRealNameError extends Error {}

export function checkLogin() {
  const user = useUser();
  if (!user || !user.id) {
    throw new NeedLoginError(`需要登录`);
  }
  return user;
}

export function checkRealName() {
  const user = useUser();
  if (!user.username) {
    throw new NeedRealNameError(`需要实名认证`);
  }
}

export function gotoPageWithSuccess(params) {
  if (typeof params == "string") {
    uni.showToast({ title: "操作成功" });
    setTimeout(async () => {
      await utils.gotoPage(params);
    }, 1000);
  } else {
    uni.showToast({ title: params.title });
    setTimeout(async () => {
      await utils.gotoPage(params.url);
    }, 1000);
  }
}

const UNI_LOGIN_PAGE = process.env.UNI_LOGIN_PAGE;
const LOGIN_HINT = "login required";
export function globalErrorHandler(err) {
  console.error("errorHandler captured...", err);
  if (err instanceof NeedLoginError || err.message == LOGIN_HINT) {
    console.log("NeedLoginError需要登录");
    utils.redirect(UNI_LOGIN_PAGE, {
      message: "此操作需要登录",
      redirect: utils.getSafeRedirect(getFullPath()),
    });
  } else if (err instanceof NeedRealNameError) {
    console.log("NeedRealNameError需要实名认证");
    utils.redirect("/views/RealNameCert", {
      justCheck: 1,
      message: "此操作需要实名认证",
      redirect: utils.getSafeRedirect(getFullPath()),
    });
  } else if (typeof err == "string") {
    uni.showModal({
      title: `错误`,
      content: err,
      showCancel: false,
    });
  } else if (err.type == "uni_error") {
    uni.showModal({
      title: `错误`,
      content: err.message || err.data,
      showCancel: false,
    });
  } else {
    console.log(`捕获异常:`, err);
  }
}
