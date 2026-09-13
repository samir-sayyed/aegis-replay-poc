export type Item = { name: string; category: string };

export function byCategory(items: Item[], category: string): Item[] {
  return items.filter((item) => item.category === category);
}
