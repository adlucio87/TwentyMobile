# Project instructions

## Verification (quality gate)

Dopo aver apportato modifiche al codice, esegui SEMPRE il quality gate:

    ./scripts/verify.sh

Questo comando rileva automaticamente le aree modificate (via `git diff`) ed esegue solo le verifiche pertinenti:

- **Flutter**   → `flutter analyze` + `flutter test`       (se cambiano `lib/`, `test/`, `*.dart`, `pubspec.yaml`)
- **Backend**   → `node --check` + `node --test`            (se cambiano `backend/`, `firebase.json`, `.firebaserc`, `firestore.rules`)

Se la verifica fallisce:
1. Leggi l'output dell'errore.
2. Correggi il problema.
3. Riesegui `./scripts/verify.sh`.
4. Ripeti finché non passa.

Non considerare il task completo finché `./scripts/verify.sh` non passa.
**Mai** committare o fare deploy con la verifica fallita.

### Maestro (on-demand)
I test E2E con Maestro non vengono eseguiti automaticamente dal quality gate né da `--all`. Vengono lanciati esclusivamente su richiesta esplicita (richiedono device/emulatore connesso):
- `./scripts/verify.sh --area maestro` oppure `./scripts/verify/maestro.sh`
- Per includerli nel verify completo: `./scripts/verify.sh --all --with-maestro`

Comandi utili:
- tutte le verifiche standard: `./scripts/verify.sh --all`
- una singola area:            `./scripts/verify.sh --area flutter|backend|maestro`

### Backend (Cloud Functions)
Le regole del registry OAuth (validazione hostname/SSRF guard, interpretazione
delle risposte GraphQL di Twenty, self-healing, rate limit) vivono in
`backend/lib/registry.js` e sono coperte da unit test col runner nativo di Node:
`cd backend && npm test`. `backend/index.js` è solo l'adapter `firebase-functions`.

Deploy (richiede `firebase login`):

    npm --prefix backend run deploy     # functions + hosting + firestore rules

Per test E2E deterministici puoi disattivare del tutto il registry condiviso
compilando l'app con `--dart-define=OAUTH_REGISTRY_URL=`.

## Esecuzione e Debug

- Quando viene richiesto di eseguire o testare l'app in debug e non viene specificato un dispositivo, utilizza **SEMPRE** "Pixel Fold" come dispositivo di default (es. `flutter run -d "Pixel Fold"`).
