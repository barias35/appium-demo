import { expect } from "@wdio/globals";
import LoginPage from "../pageobjects/login.page";
import AlertComponent from "../pageobjects/components/alert.component";

describe("My Login application", () => {
  it("should login with valid credentials", async () => {
    await LoginPage.goToLogin();

    await LoginPage.login("test@webdriver.io", "Test12345");

    await AlertComponent.waitForIsShown();

    expect(await AlertComponent.getTitleText()).toBe("Success");
    expect(await AlertComponent.getMessageText()).toBe("You are logged in!");

    await AlertComponent.accept();
  });
});
