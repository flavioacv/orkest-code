// TypeScript sample fixture
export interface User {
  id: number;
  name: string;
}

export function formatUser(u: User): string {
  return `${u.name} (#${u.id})`;
}
