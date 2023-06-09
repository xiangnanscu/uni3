export function usePage() {
  const page = ref(null);
  onLoad(() => {
    console.log("usePage onLoad");
    const pages = getCurrentPages();
    page.value = pages[pages.length - 1];
  });
  return page;
}
