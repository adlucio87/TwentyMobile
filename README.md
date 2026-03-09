# PocketCRM

PocketCRM is a Flutter-based mobile application acting as a unified client for various backend CRMs, starting with **Twenty CRM**. It allows users to manage contacts, companies, notes, and tasks on the go.

## Prerequisites
- Flutter 3.10+
- Docker & Docker Compose (for local development)

## Quick Start
Run the following command to set up the local backend and start the app:
```bash
make setup
```

## Architecture
The application uses a **Connector Pattern**:
- `CRMRepository` defines a unified interface for all operations.
- `TwentyConnector` implements `CRMRepository` acting as a GraphQL client for Twenty CRM.
- In the future, other connectors (like `MonicaConnector`) can be implemented, simply swapping the Provider implementation.

## Tech Stack
- **Framework:** Flutter
- **State Management & DI:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Navigation:** GoRouter
- **Model Generation:** Freezed & JSON Serializable
- **Storage:** Flutter Secure Storage (Tokens, URL), Hive (Cache)
- **Networking:** GraphQL (`graphql_flutter`), Dio

## Supported Backends
- Twenty CRM V1 (GraphQL)
- Monica HQ (Coming soon)

## License
PocketCRM is an open-source project distributed under the **AGPL-3.0** License.
