export function useWxShare({ title, imageUrl, desc, path }) {
  // console.log("useWxShare", { title, imageUrl, desc });
  onShareTimeline((options) => {
    const shareUrl =
      typeof path == "function" ? path(utils.getFullPath()) : path || utils.getFullPath();
    return {
      title,
      desc,
      path: shareUrl,
      imageUrl: imageUrl || "../static/jax.png",
    };
  });
  onShareAppMessage((options) => {
    // options: from:"button", target:{id,dataset, offsetTop, offsetLeft}
    const shareUrl =
      typeof path == "function" ? path(utils.getFullPath()) : path || utils.getFullPath();
    return {
      title,
      desc,
      path: shareUrl,
      imageUrl: imageUrl || "../static/jax.png",
    };
  });
}
