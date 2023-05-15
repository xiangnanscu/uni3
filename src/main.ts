import { createSSRApp } from "vue";
import App from "./App.vue";
import { createPinia } from "pinia";
import 'vant/es/toast/style';
const pinia = createPinia();

// https://pinia.vuejs.org/core-concepts/plugins.html#adding-new-external-properties
// pinia.use(({ store }) => {
//   store.router = markRaw(router);
// });
export function createApp() {
  const app = createSSRApp(App);
  app.use(pinia);
  return {
    app,
  };
}
