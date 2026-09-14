export type Visibility = "public" | "internal";
export type Item = { name: string; category: string; visibility: Visibility };

export function byCategory(items: Item[], category: string): Item[] {
  return items.filter((item) => item.category === category && item.visibility === "public");
}
