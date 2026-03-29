# TwentyMobile

TwentyMobile è un'applicazione mobile nativa sviluppata in **Flutter** che funge da client unificato per CRM backend, partendo dall'integrazione con **Twenty CRM**. L'obiettivo del progetto è permettere agli utenti di gestire contatti, aziende, note e task in mobilità, con un'interfaccia moderna, veloce e reattiva.

**Namespace del progetto:** `com.luciosoft.pocketcrm`

## 🌟 Funzionalità Implementate

- **Onboarding & Autenticazione:** Connessione a un'istanza self-hosted di Twenty CRM tramite URL e API Token personalizzati, salvati in modo sicuro, con integrazione automatica a Sentry per monitoraggio errori.
- **Modalità Demo:** Esplorazione completa dell'interfaccia e delle funzionalità tramite un ambiente isolato di test con blocco di sicurezza sulle mutazioni.
- **Dashboard (Home):** Panoramica rapida per iniziare la giornata, con saluti dinamici, task in scadenza, task di oggi e contatti recentemente visualizzati.
- **Gestione Contatti:**
  - Lista contatti interattiva con funzionalità di ricerca rapida.
  - Dettaglio contatto completo.
  - Creazione e modifica rapida dei contatti con **aggiornamento ottimistico** (Optimistic UI).
  - Condivisione del contatto ed esportazione diretta nella rubrica del sistema (iOS/Android).
  - Acquisizione rapida tramite **Scanner di Biglietti da Visita** integrato.
  - Azioni rapide per inviare email o avviare chiamate telefoniche.
- **Gestione Aziende (Companies):**
  - Lista aziende e pagina di dettaglio dedicata con contatti collegati.
  - Apertura veloce del sito web aziendale nel browser nativo.
- **Appunti e Note Avanzate:**
  - Visualizzazione cronologica delle note collegate.
  - Presa di note testuali rapide dal dettaglio o dalla home.
  - Registrazione di **Note Vocali** con salvataggio sicuro, per dettare e conservare informazioni hands-free.
- **Gestione Task e Notifiche:**
  - Lista dei task assegnati con filtro dinamico (Da completare / Completati).
  - Programmazione con date di scadenza.
  - Sistema di notifica avanzato (notifiche locali push) per ricordare task in scadenza o scaduti.

## 🏛 Architettura e Struttura del Progetto

L'architettura segue i principi del **Domain-Driven Design (DDD)** uniti a un approccio **Feature-First** nello strato di presentazione. L'app usa il **Connector Pattern** per astrarre le chiamate al CRM sorgente.
Esiste un'interfaccia astratta `CRMRepository` implementata da `TwentyConnector` (il client GraphQL per Twenty CRM). Questo permette future espansioni verso altri CRM senza modificare la logica di business o la UI.

La struttura all'interno di `lib/` è organizzata per feature:

```text
lib/
├── core/                           # Dependency injection globale (Riverpod), Router, Theme, Utils, Notifiche
├── domain/                         # Modelli dati core (Contact, Company, Note, Task), Interfacce repository
├── data/                           # Implementazione GraphQL (TwentyConnector), storage locale Hive/SecureStorage
├── presentation/                   # Strato UI (Feature-First)
│   ├── onboarding/                 # Setup iniziale e accesso Demo
│   ├── home/                       # Dashboard 
│   ├── contacts/                   # Modulo contatti
│   ├── contact_detail/             # Dettaglio contatti, player/recorder Note vocali
│   ├── companies/                  # Modulo aziende
│   ├── scan/                       # Scanner biglietti da visita
│   ├── notes/                      # Modulo per note testuali
│   └── tasks/                      # Modulo per task
└── shared/                         # Widget estetici e componenti cross-feature (ad es. blocco Demo)
```

## 🛠 Stack Tecnologico Principale

- **Framework:** Flutter (Mobile, iOS/Android ready)
- **Gestione Stato & DI:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Routing Multi-Path:** GoRouter
- **Integrazioni API:** GraphQL (`graphql_flutter`)
- **Generazione Codice:** Freezed & JSON Serializable
- **Notifiche:** `flutter_local_notifications`, `timezone`
- **Sicurezza & Storage:** Flutter Secure Storage, Hive

## 🚀 Sviluppo e Setup

Per avviare il progetto localmente:

1. Assicurati di avere l'SDK di Flutter installato.
2. Esegui il pull dei pacchetti:
   ```bash
   flutter pub get
   ```
3. Rigenera il codice dei modelli e provider (Riverpod & Freezed):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Lancia l'app su un simulatore (avendo testato a fondo i widget di layout):
   ```bash
   flutter run
   ```

5. Compila l'app bundle per il rilascio Android App Store:
   ```bash
   flutter build appbundle --release
   ```

## 📄 Licenza
TwentyMobile è un progetto open-source distribuito sotto licenza **AGPL-3.0**.
