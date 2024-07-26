export const useMapNavigate = () => {
  const chooseLocation = uni.chooseLocation;
  const wxMapNavigate = (location) => {
    const endPoint = JSON.stringify({
      //终点
      name: location.address,
      location: {
        lat: location.latitude,
        lng: location.longitude,
      },
    });
    wx.navigateToMiniProgram({
      appId: "wx7643d5f831302ab0", //要打开的小程序 appId
      path: "pages/multiScheme/multiScheme?endLoc=" + endPoint, //打开的页面路径，如果为空则打开首页
      fail: function () {
        wx.showToast({
          icon: "none",
          title: "打开失败，请重试",
        });
      },
    });
  };
  return {
    chooseLocation,
    wxMapNavigate,
  };
};
