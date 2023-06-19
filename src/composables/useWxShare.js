export function useWxShare({ title, imageUrl }) {
  console.log("useWxShare called");
  onShareTimeline((options) => {
    console.log("onShareTimeline", options);
    const page = getCurrentPages().slice(-1)[0];
    const path = page.$page.fullPath;
    return {
      title,
      path,
      imageUrl
    };
  });
  console.log("useWxShare called end");
}
