export function useUser() {
  const session = useSession();
  return session.user;
}
