export function useRealNameCert() {
  const user = useUser();
  if (!user.username) {
    console.log(
      "****useRealNameCert 未实名, 需要实名认证, 当前页面:",
      utils.getFullPath(),
    );
    return utils.gotoPage({
      url: "/views/RealNameCert",
      query: { redirect: utils.getFullPath(), message: "此操作需要先实名认证" },
      redirect: false,
    });
  }
  return true;
}
