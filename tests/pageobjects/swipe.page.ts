import { $, browser } from "@wdio/globals";
import { ChainablePromiseElement } from "webdriverio";
import BasePage from "./base.page";

class SwipePage extends BasePage {
  private get swipeTab() {
    return $("~Swipe");
  }
  private get swipeScreen() {
    return $("~Swipe-screen");
  }

  get jsFoundation() {
    return $('//android.widget.TextView[@text="JS.FOUNDATION"]');
  }

  async goToSwipe() {
    await this.waitAndClick(this.swipeTab);
    await this.waitForIsShown();
  }

  async waitForIsShown(isShown = true): Promise<boolean | void> {
    return this.swipeScreen.waitForDisplayed({
      reverse: !isShown,
      timeout: 20000,
    });
  }

  async swipeUntilVisible(element: ChainablePromiseElement, maxSwipes = 10) {
    await browser.waitUntil(
      async () => {
        if (await element.isDisplayed()) {
          return true;
        }

        const size = await browser.getWindowSize();
        const centerY = Math.floor(size.height / 2);
        const startX = Math.floor(size.width * 0.8);
        const endX = Math.floor(size.width * 0.2);

        // Swipe from right to left
        await this.swipe({ x: startX, y: centerY }, { x: endX, y: centerY });

        return await element.isDisplayed();
      },
      {
        timeout: 60000,
        timeoutMsg:
          "Element JS.FOUNDATION not found after 60 seconds of horizontal swiping",
        interval: 1000,
      },
    );
  }
}

export default new SwipePage();
