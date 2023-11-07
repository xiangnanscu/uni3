export function useWxShare({ title, imageUrl, desc, path }) {
  // console.log("useWxShare", { title, imageUrl, desc, path });
  onShareTimeline((options) => {
    const shareUrl = typeof path == "function" ? path() : path || utils.getFullPath();
    console.log({ shareUrl });
    return {
      title,
      desc,
      path: shareUrl,
      imageUrl: imageUrl || "../static/cover-share.png",
    };
  });
  onShareAppMessage((options) => {
    // options: from:"button", target:{id,dataset, offsetTop, offsetLeft}
    const shareUrl = typeof path == "function" ? path() : path || utils.getFullPath();
    console.log({ shareUrl });
    return {
      title,
      desc,
      path: shareUrl,
      imageUrl: imageUrl || "../static/cover-share.png",
    };
  });
}
