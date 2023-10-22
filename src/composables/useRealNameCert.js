export function useRealNameCert() {
  const user = useUser();
  if (!user.username) {
    console.log("useRealNameCert redirect:", utils.getFullPath());
    return utils.gotoPage({
      url: "/views/RealNameCert",
      query: { redirect: utils.getFullPath(), message: "此操作需要先实名认证" },
      redirect: false,
    });
  }
  return true;
}
