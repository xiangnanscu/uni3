export function useRealNameCert() {
  const user = useUser();
  console.log("useRealNameCert redirect", utils.getFullPath());
  if (!user.username) {
    return utils.gotoPage({
      url: "/views/RealNameCert",
      query: { redirect: utils.getFullPath(), message: "此操作需要先实名认证" },
      redirect: false,
    });
  }
  return true;
}
