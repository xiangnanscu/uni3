export function useWxShare({ title, imageUrl, desc, path }) {
  // console.log("useWxShare", { title, imageUrl, desc, path });
  onShareTimeline(async (options) => {
    const shareUrl = typeof path == "function" ? await path() : path || utils.getFullPath();
    console.log({ shareUrl });
    return {
      title: typeof title == "function" ? title() : title,
      desc,
      path: shareUrl,
      imageUrl: typeof imageUrl == "function" ? imageUrl() : imageUrl || "../static/cover-share.jpg",
    };
  });
  onShareAppMessage(async (options) => {
    // options: from:"button", target:{id,dataset, offsetTop, offsetLeft}
    const shareUrl = typeof path == "function" ? await path() : path || utils.getFullPath();
    console.log({ shareUrl });
    return {
      title: typeof title == "function" ? title() : title,
      desc,
      path: shareUrl,
      imageUrl: typeof imageUrl == "function" ? imageUrl() : imageUrl || "../static/cover-share.jpg",
    };
  });
}
