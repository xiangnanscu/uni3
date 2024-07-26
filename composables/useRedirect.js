import { ref } from "vue";
import { onLoad } from "@dcloudio/uni-app";
import { useQuery } from "~/composables/useQuery";

export function useRedirect(query) {
  if (!query) {
    query = useQuery();
  }
  const redirect = ref();
  onLoad(() => {
    if (query.redirect) {
      redirect.value = decodeURIComponent(query.redirect);
    } else {
      redirect.value = process.env.UNI_HOME_PAGE;
    }
  });
  return redirect;
}
