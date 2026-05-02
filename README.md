# Appium Course

This project is a mobile test automation framework using **Appium**, **WebdriverIO**, and **TypeScript**.

## Project Structure

- `apps/`: Contains the sample Android application (`android.wdio.native.app.v2.2.0.apk`).
- `scripts/`: Utility scripts for process cleanup and environment setup.
- `tests/`: 
  - `pageobjects/`: Implementation of the Page Object Pattern.
  - `specs/`: Test cases (Login, Forms, Swipe).
- `wdio.conf.ts`: Main WebdriverIO configuration file.

## Prerequisites

- Node.js installed.
- Android Studio / Emulator configured.
- Appium installed globally or via project dependencies.

## Installation

```bash
npm install
```

## How to Run

To start Appium and run tests on Android:

```bash
npm run e2e:android
```

Alternatively, run them separately:

1. **Start Appium:**
   ```bash
   npm run start-appium
   ```

2. **Run WDIO Tests:**
   ```bash
   npm run wdio
   ```

## Available Scripts

- `start-appium`: Starts the Appium server with CORS enabled.
- `wdio`: Executes WebdriverIO tests.
- `e2e:android`: A PowerShell script that automates cleanup, starts Appium, and runs the test suite.
