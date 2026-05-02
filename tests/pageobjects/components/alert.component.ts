import { $ } from "@wdio/globals";
import { ChainablePromiseElement } from "webdriverio";

/**
 * Reusable component for handling native Android alerts.
 *
 * Adheres to:
 * - SOLID: Single Responsibility for alert interactions.
 * - DRY: Centralizes alert selectors and actions.
 */
class AlertComponent {
  // Standard Android Alert IDs and fallback UiSelectors
  private get alertTitle() {
    return $("id=android:id/alertTitle");
  }
  private get alertMsg() {
    return $("id=android:id/message");
  }
  private get okButton() {
    return $("id=android:id/button1");
  }

  // Fallback text-based selectors for specific cases like the success alert
  private get successTitle() {
    return $('android=new UiSelector().text("Success")');
  }
  private get successMsg() {
    return $('android=new UiSelector().text("You are logged in!")');
  }

  /**
   * Wait for alert to be displayed.
   * Tries both standard ID and specific text fallback for robustness.
   */
  async waitForIsShown(isShown = true) {
    const timeout = 10000;
    if (isShown) {
      await browser.waitUntil(
        async () => {
          return (
            (await this.alertMsg.isDisplayed()) ||
            (await this.successMsg.isDisplayed())
          );
        },
        { timeout, timeoutMsg: "Alert not found" },
      );
    } else {
      await this.alertMsg.waitForDisplayed({ reverse: true, timeout });
    }
  }

  /**
   * Get text from the alert title
   */
  async getTitleText() {
    if (await this.successTitle.isDisplayed())
      return this.successTitle.getText();
    await this.alertTitle.waitForDisplayed();
    return this.alertTitle.getText();
  }

  /**
   * Get text from the alert message
   */
  async getMessageText() {
    if (await this.successMsg.isDisplayed()) return this.successMsg.getText();
    await this.alertMsg.waitForDisplayed();
    return this.alertMsg.getText();
  }

  /**
   * Click the OK button
   */
  async accept() {
    await this.okButton.waitForDisplayed();
    await this.okButton.click();
  }
}

export default new AlertComponent();
