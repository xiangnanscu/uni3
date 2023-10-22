import path from "path";

export function useWxShare({ title, imageUrl, desc, path }) {
  // console.log("useWxShare", { title, imageUrl, desc });
  onShareTimeline((options) => {
    const path = typeof path == "function" ? path(options) : path || utils.getFullPath();
    return {
      title,
      desc,
      path,
      imageUrl: imageUrl || "../static/jax.png",
    };
  });
  onShareAppMessage((options) => {
    const path = typeof path == "function" ? path(options) : path || utils.getFullPath();
    return {
      title,
      desc,
      path,
      imageUrl: imageUrl || "../static/jax.png",
    };
  });
}
