import { expect } from "@wdio/globals";
import SwipePage from "../pageobjects/swipe.page";

describe("Swipe gestures - Find JS Foundation", () => {
  it("should swipe until JS.FUNDATION is visible", async () => {
    await SwipePage.goToSwipe();

    await SwipePage.swipeUntilVisible(SwipePage.jsFoundation, 15);

    expect(await SwipePage.jsFoundation.isDisplayed()).toBe(true);

    const text = await SwipePage.jsFoundation.getText();
    console.log(`Found element with text: ${text}`);
  });
});
