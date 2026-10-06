# Project instructions

## Verification (quality gate)

Dopo aver apportato modifiche al codice, esegui SEMPRE il quality gate:

    ./scripts/verify.sh

Questo comando rileva automaticamente le aree modificate (via `git diff`) ed esegue solo le verifiche pertinenti:

- **Flutter**   → `flutter analyze` + `flutter test`       (se cambiano `lib/`, `test/`, `*.dart`, `pubspec.yaml`)
- **Functions** → `npm test` / build                       (se cambia `functions/`)
- **Firebase**  → validazione di `firebase.json` / `*.rules` (se cambia la config Firebase)
- **Maestro**   → flussi E2E su device (OPZIONALE)

Se la verifica fallisce:
1. Leggi l'output dell'errore.
2. Correggi il problema.
3. Riesegui `./scripts/verify.sh`.
4. Ripeti finché non passa.

Non considerare il task completo finché `./scripts/verify.sh` non passa.
**Mai** committare o fare deploy con la verifica fallita.

### Maestro (opzionale)
Maestro richiede un device/emulatore connesso. Se non è connesso alcun device, lo script salta Maestro (`⚠`) senza bloccare il task. Non fallire il task solo perché i test su device fisico non sono eseguibili.

Comandi utili:
- tutte le verifiche: `./scripts/verify.sh --all`
- una singola area:   `./scripts/verify.sh --area flutter|functions|firebase|maestro`
