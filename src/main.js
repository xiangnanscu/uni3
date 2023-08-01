import "regenerator-runtime/runtime";
import { createSSRApp } from "vue";
import App from "./App.vue";
import { createPinia } from "pinia";
import uniSetup from "./uniSetup";

const pinia = createPinia();

// https://pinia.vuejs.org/core-concepts/plugins.html#adding-new-external-properties
// pinia.use(({ store }) => {
//   store.router = markRaw(router);
// });
export function createApp() {
  uniSetup();
  const app = createSSRApp(App);
  app.use(pinia);
  app.mixin({
    computed: {
      user() {
        const { session } = useSession();
        return session.user;
      }
    },
    methods: {
      previewImage(url) {
        if (url.startsWith("//")) {
          url = "https:" + url;
        } else if (url.startsWith("http:")) {
          url = `https:${url.slice(5)}`;
        }
        uni.previewImage({ urls: [url], current: 0 });
      }
    }
  });
  setTimeout(() => {
    app.config.errorHandler = (err, instance, info) => {
      console.error("errorHandler captured...", err);
      console.log(instance, info);
      if (err.type == "uni_error") {
        uni.showModal({
          title: `错误`,
          content: err.message,
          showCancel: false
        });
      }
    };
  });
  return {
    app
  };
}
