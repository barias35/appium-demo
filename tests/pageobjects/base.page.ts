import { browser, $ } from "@wdio/globals";
import { ChainablePromiseElement } from "webdriverio";

export default class BasePage {
  get selector(): string {
    return "";
  }

  async waitForIsShown(isShown = true): Promise<boolean | void> {
    return $(this.selector).waitForDisplayed({
      reverse: !isShown,
    });
  }

  async waitAndClick(element: ChainablePromiseElement) {
    await element.waitForDisplayed();
    await element.click();
  }

  async waitAndSetValue(element: ChainablePromiseElement, value: string) {
    await element.waitForDisplayed();
    await element.setValue(value);
  }

  async waitAndGetText(element: ChainablePromiseElement): Promise<string> {
    await element.waitForDisplayed();
    return element.getText();
  }

  async hideKeyboard() {
    if (await browser.isKeyboardShown()) {
      await browser.hideKeyboard();
    }
  }

  async swipe(from: { x: number; y: number }, to: { x: number; y: number }) {
    await browser.performActions([
      {
        type: "pointer",
        id: "finger1",
        parameters: { pointerType: "touch" },
        actions: [
          { type: "pointerMove", duration: 0, x: from.x, y: from.y },
          { type: "pointerDown", button: 0 },
          { type: "pointerMove", duration: 1000, x: to.x, y: to.y },
          { type: "pointerUp", button: 0 },
        ],
      },
    ]);
    await browser.pause(1000);
  }
}
