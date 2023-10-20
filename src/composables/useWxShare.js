export function useWxShare({ title, imageUrl, desc, path }) {
  // console.log("useWxShare", { title, imageUrl, desc });
  onShareTimeline((options) => {
    return {
      title,
      desc,
      path: path || utils.getFullPath(),
      imageUrl: imageUrl || "../static/jax.png",
    };
  });
  onShareAppMessage((options) => {
    return {
      title,
      desc,
      path: path || utils.getFullPath(),
      imageUrl: imageUrl || "../static/jax.png",
    };
  });
}
