export function usePage() {
  const pages = getCurrentPages(); //页面列表
  const page = pages[pages.length - 1].$page; //路由名称
  return page;
}
