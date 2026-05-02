import { $ } from "@wdio/globals";
import BasePage from "./base.page";

class LoginPage extends BasePage {
  private get loginTab() {
    return $("~Login");
  }
  private get emailField() {
    return $("~input-email");
  }
  private get passwordField() {
    return $("~input-password");
  }
  private get loginButton() {
    return $("~button-LOGIN");
  }

  get selector(): string {
    return "~Login-screen";
  }

  async goToLogin() {
    await this.waitAndClick(this.loginTab);
    await this.waitForIsShown();
  }

  async login(email: string, password: string) {
    await this.waitAndSetValue(this.emailField, email);
    await this.waitAndSetValue(this.passwordField, password);
    await this.waitAndClick(this.loginButton);
  }
}

export default new LoginPage();
