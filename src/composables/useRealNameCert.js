import { useUser } from "~/composables/useAuth";

export function useRealNameCert() {
  const user = useUser();
  if (!user.username) {
    console.log("****useRealNameCert 未实名, 需要实名认证, 当前页面:", utils.getFullPath());
    return utils.gotoPage({
      url: "/views/RealNameCert",
      query: { message: "此操作需要先实名认证", redirect: utils.getFullPath() },
      redirect: true,
    });
  }
  return true;
}
