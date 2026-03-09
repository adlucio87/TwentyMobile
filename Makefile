# Makefile

.PHONY: backend-up backend-down backend-logs backend-reset flutter-run setup

# Avvia Twenty CRM in locale
backend-up:
	docker compose up -d
	@echo "⏳ Attendo che Twenty sia pronto..."
	@sleep 10
	@echo "✅ Twenty CRM disponibile su http://localhost:3000"

# Ferma i container
backend-down:
	docker compose down

# Vedi i log
backend-logs:
	docker compose logs -f twenty

# Reset completo (cancella tutti i dati)
backend-reset:
	docker compose down -v
	docker compose up -d

# Avvia Flutter (assicurati di avere un device/emulator connesso)
flutter-run:
	flutter run

# Setup completo da zero
setup: backend-up
	@echo "⏳ Attendo inizializzazione Twenty..."
	@sleep 20
	@echo ""
	@echo "🎉 Setup completato!"
	@echo ""
	@echo "1. Apri http://localhost:3000 nel browser"
	@echo "2. Crea un account admin"
	@echo "3. Vai su Settings → API & Webhooks → Generate API Key"
	@echo "4. Copia il token e incollalo nell'app Flutter"
	@echo ""
	flutter run
