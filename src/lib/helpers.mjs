import { usePost } from "@/composables/usePost";

export async function getRoles(data) {
  return await usePost(`/role/get_roles`, data);
}

export async function getPassedRoles(data) {
  return await usePost(`/role/get_roles`, { ...data, status: "通过" });
}
