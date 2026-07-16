import { expect, it } from "vitest";
import { add } from "./calculator";

it("adds two numbers", () => {
  expect(add(2, 2)).toBe(4);
});
