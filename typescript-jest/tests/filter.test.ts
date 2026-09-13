import { byCategory, Item } from "../src/filter";

describe("byCategory", () => {
  const items: Item[] = [
    { name: "alarm", category: "audio" },
    { name: "calendar", category: "productivity" }
  ];

  it("retains items in the requested category", () => {
    expect(byCategory(items, "audio")).toEqual([items[0]]);
  });

  it("returns an empty list when category is unknown", () => {
    expect(byCategory(items, "missing")).toEqual([]);
  });
});
