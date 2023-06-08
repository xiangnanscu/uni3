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
    }
  });
  setTimeout(() => {
    app.config.errorHandler = (err, instance, info) => {
      console.log("errorHandler captured...", err, instance, info);
    };
  });
  return {
    app
  };
}
