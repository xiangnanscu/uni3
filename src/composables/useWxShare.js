export function useWxShare({ title, imageUrl }) {
  onShareTimeline((options) => {
    return {
      title,
      path: utils.getFullPath(),
      imageUrl
    };
  });
}
