import { $ } from "@wdio/globals";
import BasePage from "./base.page";

class FormsPage extends BasePage {
  private get formsTab() {
    return $("~Forms");
  }
  private get inputField() {
    return $("~text-input");
  }
  private get inputTextResult() {
    return $("~input-text-result");
  }
  private get switchButton() {
    return $("~switch");
  }
  private get switchText() {
    return $("~switch-text");
  }
  private get dropdown() {
    return $("~Dropdown");
  }
  private get activeButton() {
    return $("~button-Active");
  }

  get selector(): string {
    return "~Forms-screen";
  }

  async goToForms() {
    await this.waitAndClick(this.formsTab);
    await this.waitForIsShown();
  }

  async fillInput(text: string) {
    await this.waitAndSetValue(this.inputField, text);
  }

  async getInputResultText() {
    return this.waitAndGetText(this.inputTextResult);
  }

  async toggleSwitch() {
    await this.waitAndClick(this.switchButton);
  }

  async getSwitchText() {
    return this.waitAndGetText(this.switchText);
  }

  async clickActiveButton() {
    await this.waitAndClick(this.activeButton);
  }
}

export default new FormsPage();
