# .maestro — Flussi E2E (Maestro)

Questa cartella raccoglie i flussi E2E [Maestro](https://maestro.mobile.dev/) dell'app.

## Convenzioni di naming

- `login.yaml`         — autenticazione / onboarding
- `home.yaml`          — avvio app e schermata principale
- `save_article.yaml`  — salvataggio di un contenuto (link/articolo)
- `<feature>.yaml`     — un flusso per funzionalità principale

## Struttura di un flusso

```yaml
appId: <bundle.id>
name: "<nome descrittivo>"
tags:
  - e2e
---
- launchApp
- extendedWaitUntil:
    visible: "<schermata iniziale>"
    timeout: 15000
```

## Esecuzione

```bash
scripts/verify/maestro.sh        # esegue tutti i flussi in .maestro/
# oppure
export PATH="$PATH:$HOME/.maestro/bin"
maestro test .maestro
```
