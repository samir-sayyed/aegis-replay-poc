import { byCategory, Item } from "../src/filter";

describe("public product catalog", () => {
  const items: Item[] = [
    { name: "wireless headphones", category: "audio", visibility: "public" },
    { name: "support escalation dashboard", category: "audio", visibility: "internal" },
    { name: "weekly planner", category: "productivity", visibility: "public" }
  ];

  it("never exposes internal products in a public category", () => {
    expect(byCategory(items, "audio")).toEqual([items[0]]);
  });

  it("returns an empty list when category is unknown", () => {
    expect(byCategory(items, "missing")).toEqual([]);
  });
});
