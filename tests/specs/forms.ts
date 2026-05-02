import { expect } from "@wdio/globals";
import FormsPage from "../pageobjects/forms.page";
import AlertComponent from "../pageobjects/components/alert.component";

describe("Forms Screen Tests", () => {
  it("should fill the form successfully", async () => {
    await FormsPage.goToForms();

    const testText = "Hello Appium";
    await FormsPage.fillInput(testText);
    expect(await FormsPage.getInputResultText()).toBe(testText);

    const initialSwitchText = await FormsPage.getSwitchText();
    await FormsPage.toggleSwitch();
    expect(await FormsPage.getSwitchText()).not.toBe(initialSwitchText);

    await FormsPage.clickActiveButton();

    await AlertComponent.waitForIsShown();
    expect(await AlertComponent.getMessageText()).toContain("This button is");
    await AlertComponent.accept();
  });
});
