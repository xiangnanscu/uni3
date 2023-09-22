export function useWxShare({ title, imageUrl, desc }) {
  // console.log("useWxShare", { title, imageUrl, desc });
  onShareTimeline((options) => {
    return {
      title,
      desc,
      path: utils.getFullPath(),
      imageUrl
    };
  });
  onShareAppMessage((options) => {
    return {
      title,
      desc,
      path: utils.getFullPath(),
      imageUrl
    };
  });
}
