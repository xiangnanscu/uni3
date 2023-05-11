export function useDisableWeixinShare() {
  function onBridgeReady() {
    // eslint-disable-next-line no-undef
    WeixinJSBridge.call("hideOptionMenu");
  }
  const isWeixinBrowser = ref(false);
  onMounted(() => {
    isWeixinBrowser.value = isWeixin();
    if (isWeixinBrowser.value) {
      if (typeof WeixinJSBridge == "undefined") {
        if (document.addEventListener) {
          document.addEventListener(
            "WeixinJSBridgeReady",
            onBridgeReady,
            false
          );
        } else if (document.attachEvent) {
          document.attachEvent("WeixinJSBridgeReady", onBridgeReady);
          document.attachEvent("onWeixinJSBridgeReady", onBridgeReady);
        }
      } else {
        // eslint-disable-next-line no-undef
        WeixinJSBridge.call("hideOptionMenu");
      }
    }
  });
  return {
    isWeixinBrowser,
  };
}
