# Appium Curso

Este projeto é um framework de automação de testes mobile utilizando **Appium**, **WebdriverIO** e **TypeScript**.

## Estrutura do Projeto

- `apps/`: Contém o aplicativo Android de exemplo (`android.wdio.native.app.v2.2.0.apk`).
- `scripts/`: Scripts utilitários para limpeza de processos e inicialização do ambiente.
- `tests/`: 
  - `pageobjects/`: Implementação do padrão Page Object.
  - `specs/`: Casos de teste (Login, Forms, Swipe).
- `wdio.conf.ts`: Configuração principal do WebdriverIO.

## Pré-requisitos

- Node.js instalado.
- Android Studio / Emulator configurado.
- Appium instalado globalmente ou via dependências do projeto.

## Instalação

```bash
npm install
```

## Como Executar

Para iniciar o Appium e rodar os testes no Android:

```bash
npm run e2e:android
```

Ou separadamente:

1. Iniciar Appium:
   ```bash
   npm run start-appium
   ```

2. Rodar testes WDIO:
   ```bash
   npm run wdio
   ```

## Scripts Disponíveis

- `start-appium`: Inicia o servidor Appium com CORS permitido.
- `wdio`: Executa os testes do WebdriverIO.
- `e2e:android`: Script PowerShell para automatizar a limpeza, inicialização do Appium e execução dos testes.
