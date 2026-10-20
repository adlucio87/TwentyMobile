#!/usr/bin/env python3
"""Genera e valida metadati completi per TwentyMobile (PocketCRM) in tutte le 9 lingue target."""
import json
import re
from pathlib import Path

ROOT = Path("/Volumes/SSD 990 PRO/Developments/Works/pocketcrm")
M = ROOT / "store/metadata"

# Detect version code from pubspec.yaml
pub = (ROOT / "pubspec.yaml").read_text()
m = re.search(r"^version:\s*([^\s+]+)\+([0-9]+)", pub, re.M)
ver_name, ver_code = m.group(1), m.group(2)
print(f"Versione TwentyMobile: {ver_name} (build code {ver_code})")

DATA = {
    "en-US": {
        "title": "TwentyMobile: Twenty CRM",
        "subtitle": "Your CRM, Your Data",
        "short_description": "Native mobile app for Twenty CRM. Self-hosted, private, open source.",
        "keywords": "CRM,twenty,self-hosted,contacts,leads,sales,open source,business,scanner,pipeline,tasks",
        "promotional_text": "Connect directly to your Twenty CRM instance on the go. 100% private, native and open source.",
        "release_notes": "• Enhanced OAuth 2.0 PKCE & SSO authentication support.\n• Improved Twenty CRM synchronization performance.\n• Business card scanner optimizations & quick lead capture.\n• Stability improvements and minor UI refinements.\n",
        "full_description": """TwentyMobile — Your CRM, Your Data.
The first native mobile app for Twenty CRM. Connect directly to your self-hosted instance and manage your business relationships on the go — privately, securely, without compromise.

YOUR DATA STAYS YOURS
TwentyMobile connects directly to your own Twenty CRM instance. No third-party proxy servers, no tracking, no subscription fees. Your contacts, your rules.

TODAY SCREEN — YOUR DAILY HQ
Start every morning with a clear view of what matters most. Overdue tasks, today's priorities, tomorrow's agenda and recent contacts — all in one unified, responsive place.

CONTACTS & COMPANIES PIPELINE
Access all your standard and custom workspace tables right from your pocket. Search, filter, call, email, or navigate to companies with a single tap.

OPPORTUNITIES & CUSTOM OBJECTS
PocketCRM adapts to your CRM setup, not the other way around. Access standard and custom tables (such as Opportunities or custom reports) defined on your Twenty server with dynamic form layouts and smart relation pickers.

SCAN BUSINESS CARDS
Point your camera at any paper business card and TwentyMobile instantly extracts name, email, phone and company. Save directly into your CRM with zero manual data entry.

SMART REMINDERS & TASKS
Set due dates and times on your tasks and receive local push notifications before deadlines. Never miss a critical customer follow-up again.

HIGHLIGHTS:
• Contacts, Companies, Opportunities, Tasks and Notes
• Full support for custom objects and dynamic schemas
• Business card scanner with on-device text recognition
• Offline cache & background sync
• Dark and Light theme matching Twenty CRM aesthetic
• Universal: iPhone, iPad, and Mac

PRIVACY FIRST
TwentyMobile is 100% open source. All network traffic travels strictly between your device and your Twenty CRM server.

REQUIREMENTS:
A running Twenty CRM instance (self-hosted or cloud managed). Get started at twenty.com. Use the built-in demo mode to explore the app instantly without setup."""
    },
    "it-IT": {
        "title": "TwentyMobile: Twenty CRM",
        "subtitle": "Il tuo CRM, i tuoi dati",
        "short_description": "App mobile nativa per Twenty CRM. Self-hosted, privata e open source.",
        "keywords": "CRM,twenty,self-hosted,contatti,vendite,open source,lead,aziende,scanner,promemoria,clienti",
        "promotional_text": "Collegati direttamente alla tua istanza Twenty CRM. 100% privato, nativo e open source.",
        "release_notes": "• Migliorato il supporto al login OAuth 2.0 PKCE e SSO.\n• Prestazioni di sincronizzazione con Twenty CRM velocizzate.\n• Ottimizzazioni per lo scanner di biglietti da visita.\n• Raffinamenti dell'interfaccia utente e maggiore stabilità.\n",
        "full_description": """TwentyMobile — Il tuo CRM, i tuoi dati.
La prima applicazione mobile nativa per Twenty CRM. Collegati direttamente alla tua istanza self-hosted e gestisci contatti, clienti e vendite ovunque ti trovi, in totale sicurezza e privacy.

I TUOI DATI RESTANO TUOI
TwentyMobile comunica in modo diretto ed esclusivo con la tua istanza Twenty CRM. Nessun server intermedio di terze parti, nessun tracciamento e nessun abbonamento nascosto. I tuoi contatti, le tue regole.

SCHERMATA OGGI — IL TUO QUARTIER GENERALE
Inizia la giornata con una visione limpida delle tue priorità: attività scadute, appuntamenti di oggi, agenda di domani e contatti recenti in un'unica interfaccia reattiva.

GESTIONE CONTATTI & AZIENDE
Accedi a tutte le tabelle standard e personalizzate del tuo workspace. Cerca, filtra, chiama, invia email o visualizza la scheda completa dell'azienda con un solo tocco.

OPPORTUNITÀ & OGGETTI PERSONALIZZATI
TwentyMobile si adatta alla configurazione del tuo CRM: visualizza opportunità commerciali, campi personalizzati e relazioni collegate con selettori intelligenti e moduli dinamici.

SCANNER BIGLIETTI DA VISITA
Inquadra un biglietto da visita con la fotocamera: l'app riconosce all'istante nome, email, numero di telefono e azienda, permettendoti di salvare il nuovo lead nel CRM in un attimo.

PROMEMORIA & ATTIVITÀ
Imposta scadenze per le tue attività e ricevi notifiche locali prima delle scadenze per non perdere mai un follow-up con i tuoi clienti.

CARATTERISTICHE PRINCIPALI:
• Contatti, Aziende, Opportunità, Attività e Note
• Supporto completo per oggetti personalizzati Twenty CRM
• Scanner biglietti da visita con riconoscimento testo on-device
• Modalità tema Scuro e Chiaro in stile Twenty CRM
• Cache offline e sincronizzazione rapida

REQUISITI:
Un'istanza Twenty CRM attiva (self-hosted o gestita). È disponibile una modalità demo integrata per provare tutte le funzionalità senza configurazione."""
    },
    "es-ES": {
        "title": "TwentyMobile: Twenty CRM",
        "subtitle": "Tu CRM, tus propios datos",
        "short_description": "App móvil nativa para Twenty CRM. Self-hosted, privada y open source.",
        "keywords": "CRM,twenty,self-hosted,contactos,ventas,open source,leads,empresas,escaner,tareas,negocios",
        "promotional_text": "Conéctate directamente a tu instancia de Twenty CRM. 100% privado y de código abierto.",
        "release_notes": "• Compatibilidad mejorada con autenticación OAuth 2.0 PKCE y SSO.\n• Mayor velocidad de sincronización con Twenty CRM.\n• Optimizaciones en el escáner de tarjetas de visita.\n• Mejoras de estabilidad y ajustes de interfaz.\n",
        "full_description": """TwentyMobile — Tu CRM, tus datos.
La primera aplicación móvil nativa para Twenty CRM. Conéctate directamente a tu instancia autoalojada (self-hosted) y gestiona tus relaciones comerciales desde cualquier lugar, con total privacidad y seguridad.

TUS DATOS SON SIEMPRE TUYOS
TwentyMobile se comunica exclusivamente con tu propio servidor de Twenty CRM. Sin intermediarios, sin rastreo de datos y sin tarifas ocultas. Tus contactos, tus reglas.

PANTALLA HOY — TU CENTRO DIARIO
Comienza cada mañana con una visión clara de lo que importa: tareas pendientes, prioridades del día, agenda de mañana y contactos recientes en un solo lugar.

GESTIÓN DE CONTACTOS Y EMPRESAS
Accede a todas las tablas estándar y personalizadas de tu espacio de trabajo. Busca, filtra, llama o envía correos con un solo toque.

OPORTUNIDADES Y OBJETOS PERSONALIZADOS
TwentyMobile se adapta a tu flujo de trabajo: visualiza oportunidades de venta y tablas dinámicas con formularios interactivos y selectores inteligentes.

ESCÁNER DE TARJETAS DE VISITA
Apunta con tu cámara a cualquier tarjeta de visita y extrae automáticamente nombre, correo, teléfono y empresa para guardarlos al instante en tu CRM.

RECORDATORIOS Y SEGUIMIENTOS
Configura fechas límite en tus tareas y recibe notificaciones locales antes de los vencimientos.

CARACTERÍSTICAS:
• Contactos, Empresas, Oportunidades, Tareas y Notas
• Soporte completo para objetos dinámicos de Twenty CRM
• Reconocimiento de texto en dispositivo
• Tema oscuro y claro elegante
• Modo demo para probar la app sin configuración previa."""
    },
    "fr-FR": {
        "title": "TwentyMobile: Twenty CRM",
        "subtitle": "Votre CRM, vos données",
        "short_description": "App mobile native pour Twenty CRM. Self-hosted, privée et open source.",
        "keywords": "CRM,twenty,self-hosted,contacts,ventes,open source,leads,entreprises,scanner,taches,clients",
        "promotional_text": "Connectez-vous directement à votre instance Twenty CRM. 100% privé et open source.",
        "release_notes": "• Prise en charge améliorée de l'authentification OAuth 2.0 PKCE et SSO.\n• Performances de synchronisation Twenty CRM optimisées.\n• Améliorations du scanner de cartes de visite.\n• Corrections de bugs et stabilité renforcée.\n",
        "full_description": """TwentyMobile — Votre CRM, vos données.
La première application mobile native pour Twenty CRM. Connectez-vous directement à votre instance auto-hébergée et gérez vos prospects, clients et opportunités où que vous soyez.

VOS DONNÉES RESTENT LES VÔTRES
TwentyMobile communique exclusivement avec votre propre serveur Twenty CRM. Aucun serveur intermédiaire, aucune collecte de données et aucun abonnement requis.

ÉCRAN AUJOURD'HUI — VOTRE QG QUOTIDIEN
Démarrez chaque journée avec une vue claire sur vos priorités : tâches en retard, priorités du jour, agenda de demain et contacts récents réunis en un seul endroit.

CONTACTS ET ENTREPRISES
Accédez à toutes vos données clients. Recherchez, filtrez, appelez ou envoyez des emails en un clic depuis votre téléphone ou tablette.

OPPORTUNITÉS ET OBJETS PERSONNALISÉS
L'application s'adapte à votre espace de travail : gérez les opportunités de vente, formulaires dynamiques et relations personnalisées.

SCANNER DE CARTES DE VISITE
Scannez n'importe quelle carte de visite avec votre appareil photo pour extraire instantanément le nom, l'email, le téléphone et l'entreprise directement dans Twenty CRM.

RAPPELS ET TÂCHES
Planifiez des rappels pour ne jamais manquer une relance client grâce aux notifications push locales.

FONCTIONNALITÉS :
• Contacts, Entreprises, Opportunités, Tâches et Notes
• Compatibilité complète avec les objets sur mesure de Twenty CRM
• Scanner de cartes de visite sur l'appareil
• Thèmes sombre et clair modernes
• Mode démo disponible sans configuration préalable."""
    },
    "de-DE": {
        "title": "TwentyMobile: Twenty CRM",
        "subtitle": "Dein CRM, deine Daten",
        "short_description": "Native mobile App für Twenty CRM. Self-hosted, privat und Open Source.",
        "keywords": "CRM,twenty,self-hosted,kontakte,vertrieb,open source,leads,firmen,scanner,aufgaben,kunden",
        "promotional_text": "Verbinde dich direkt mit deiner Twenty CRM Instanz. 100% privat und Open Source.",
        "release_notes": "• Verbesserte Unterstützung für OAuth 2.0 PKCE und SSO.\n• Schnellere Synchronisation mit deiner Twenty CRM Instanz.\n• Optimierter Visitenkarten-Scanner.\n• UI-Feinschliff und Stabilitätsverbesserungen.\n",
        "full_description": """TwentyMobile — Dein CRM, deine Daten.
Die erste native mobile App für Twenty CRM. Verbinde dich direkt mit deiner selbst gehosteten Instanz und verwalte Kontakte, Deals und Aufgaben unterwegs — privat, sicher und unabhängig.

DEINE DATEN GEHÖREN DIR
TwentyMobile kommuniziert direkt mit deinem Twenty CRM Server. Keine zwischengeschalteten Drittanbieter-Server, kein Tracking, keine versteckten Kosten. Deine Daten, deine Regeln.

HEUTE-DASHBOARD — DEIN TÄGLICHES HQ
Starte strukturiert in den Tag: Überfällige Aufgaben, heutige Prioritäten, morgige Termine und aktuelle Kontakte übersichtlich auf einen Blick.

KONTAKTE & UNTERNEHMEN
Voller Zugriff auf deine Kontakte und Firmen. Filtern, Anrufen, E-Mails schreiben oder Details ansehen mit nur einem Fingertipp.

OPPORTUNITIES & BENUTZERDEFINIERTE OBJEKTE
TwentyMobile passt sich deinem CRM an: Verwalte Vertriebschancen, dynamische Felder und verknüpfte Objekte nahtlos auf dem Smartphone.

VISITENKARTEN-SCANNER
Richte die Kamera auf eine Visitenkarte und übernehme Name, E-Mail, Telefon und Firma sekundenschnell direkt in dein CRM.

AUFGABEN & ERINNERUNGEN
Setze Fristen für deine Aufgaben und erhalte rechtzeitige Benachrichtigungen vor Fälligkeit.

HIGHLIGHTS:
• Kontakte, Unternehmen, Opportunities, Aufgaben & Notizen
• Unterstützung für dynamische Twenty CRM Schemas
• Visitenkarten-Scanner mit lokaler Texterkennung
• Dunkles und helles Twenty CRM Design
• Integrierter Demo-Modus zum sofortigen Ausprobieren."""
    },
    "pt-BR": {
        "title": "TwentyMobile: Twenty CRM",
        "subtitle": "Seu CRM, seus dados",
        "short_description": "App móvel nativo para Twenty CRM. Self-hosted, privado e open source.",
        "keywords": "CRM,twenty,self-hosted,contatos,vendas,open source,leads,empresas,scanner,tarefas,negocios",
        "promotional_text": "Conecte-se diretamente à sua instância do Twenty CRM. 100% privado e código aberto.",
        "release_notes": "• Suporte aprimorado para login OAuth 2.0 PKCE e SSO.\n• Desempenho de sincronização com o Twenty CRM otimizado.\n• Melhorias no scanner de cartões de visita.\n• Ajustes de estabilidade e refinamentos visuais.\n",
        "full_description": """TwentyMobile — Seu CRM, seus dados.
O primeiro aplicativo móvel nativo para Twenty CRM. Conecte-se diretamente à sua instância auto-hospedada e gerencie relacionamentos comerciais onde estiver, com total privacidade e controle.

SEUS DADOS SÃO SEUS
O TwentyMobile comunica-se exclusivamente com o seu próprio servidor do Twenty CRM. Sem intermediários, sem rastreamento e sem mensalidades ocultas.

TELA HOJE — SEU QG DIÁRIO
Comece o dia com foco total: tarefas atrasadas, prioridades de hoje, agenda de amanhã e contatos recentes em um único painel.

CONTATOS E EMPRESAS
Acesse todas as tabelas padrão e customizadas do seu workspace. Pesquise, filtre, ligue ou envie e-mails com apenas um toque.

OPORTUNIDADES E OBJETOS PERSONALIZADOS
O app adapta-se ao seu fluxo de trabalho: visualize oportunidades de negócios e tabelas dinâmicas com formulários intuitivos.

SCANNER DE CARTÕES DE VISITA
Aponte a câmera para um cartão de visitas de papel e extraia instantaneamente nome, e-mail, telefone e empresa para salvar no CRM.

LEMBRETES INTELIGENTES
Defina datas de vencimento e receba notificações locais antes dos prazos para nunca perder um contato importante.

DESTAQUES:
• Contatos, Empresas, Oportunidades, Tarefas e Notas
• Suporte a objetos e esquemas dinâmicos do Twenty CRM
• Reconhecimento de texto diretamente no aparelho
• Tema Escuro e Claro elegantes
• Modo demo para testar sem configuração prévia."""
    },
    "pl-PL": {
        "title": "TwentyMobile: Twenty CRM",
        "subtitle": "Twój CRM, Twoje dane",
        "short_description": "Natywna aplikacja dla Twenty CRM. Self-hosted, prywatna i open source.",
        "keywords": "CRM,twenty,self-hosted,kontakty,sprzedaz,open source,leads,firmy,skaner,zadania,klienci",
        "promotional_text": "Połącz się bezpośrednio ze swoją instancją Twenty CRM. 100% prywatności i open source.",
        "release_notes": "• Ulepszone wsparcie logowania OAuth 2.0 PKCE i SSO.\n• Zoptymalizowana prędkość synchronizacji z Twenty CRM.\n• Usprawnienia skanera wizytówek biznesowych.\n• Poprawki stabilności i interfejsu użytkownika.\n",
        "full_description": """TwentyMobile — Twój CRM, Twoje dane.
Pierwsza natywna aplikacja mobilna dla Twenty CRM. Połącz się bezpośrednio ze swoją instancją self-hosted i zarządzaj relacjami biznesowymi z dowolnego miejsca — bezpiecznie, prywatnie i bez kompromisów.

TWOJE DANE NALEŻĄ DO CIEBIE
TwentyMobile łączy się bezpośrednio z Twoim serwerem Twenty CRM. Brak pośredników, brak śledzenia i brak opłat subskrypcyjnych.

EKRAN DZISIAJ — TWOJE CENTRUM DOWODZENIA
Rozpocznij każdy dzień z jasnym widokiem na priorytety: zaległe zadania, dzisiejsze spotkania, jutrzejszy plan i ostatnie kontakty w jednym miejscu.

KONTAKTY I FIRMY
Dostęp do wszystkich tabel Twojej przestrzeni roboczej. Wyszukuj, filtruj, dzwoń i wysyłaj e-maile za jednym dotknięciem.

SZANSE SPRZEDAŻY I OBIEKTY NIESTANDARDOWE
Aplikacja dostosowuje się do Twojego CRM: przeglądaj szanse sprzedaży i dynamiczne formularze powiązane z Twoim serwerem.

SKANER WIZYTÓWEK
Skieruj aparat na wizytówkę, a TwentyMobile automatycznie odczyta imię, e-mail, telefon i firmę, zapisując nowy kontakt w bazie.

ZADANIA I PRZYPOMNIENIA
Ustawiaj terminy i otrzymuj powiadomienia przed upływem czasu, aby nigdy nie przegapić kontaktu z klientem.

NAJWAŻNIEJSZE CECHY:
• Kontakty, Firmy, Szanse, Zadania i Notatki
• Pełna obsługa schematów dynamicznych Twenty CRM
• Skaner wizytówek z przetwarzaniem na urządzeniu
• Nowoczesny motyw ciemny i jasny
• Wbudowany tryb demonstracyjny bez konfiguracji."""
    },
    "ru-RU": {
        "title": "TwentyMobile: CRM Клиент",
        "subtitle": "Ваша CRM, ваши данные",
        "short_description": "Клиент для Twenty CRM. Self-hosted, приватный и с открытым кодом.",
        "keywords": "CRM,twenty,self-hosted,контакты,продажи,open source,лиды,компании,сканер,задачи,клиенты",
        "promotional_text": "Подключайтесь к вашей Twenty CRM напрямую. 100% приватность и открытый код.",
        "release_notes": "• Улучшена поддержка авторизации OAuth 2.0 PKCE и SSO.\n• Повышена скорость синхронизации с Twenty CRM.\n• Оптимизирован сканер визитных карточек.\n• Повышена стабильность и улучшен интерфейс.\n",
        "full_description": """TwentyMobile — Ваша CRM, ваши данные.
Первое нативное мобильное приложение для Twenty CRM. Подключайтесь напрямую к вашему собственному серверу (self-hosted) и управляйте контактами, сделками и задачами в дороге — безопасно и конфиденциально.

ВАШИ ДАННЫЕ ПРИНАДЛЕЖАТ ТОЛЬКО ВАМ
TwentyMobile работает напрямую с вашим сервером Twenty CRM. Без сторонних серверов, сбора данных или подписок.

ЭКРАН СЕГОДНЯ — ВАШ ЦЕНТР УПРАВЛЕНИЯ
Начинайте день с обзора главного: просроченные дела, задачи на сегодня, планы на завтра и недавние контакты в одном месте.

КОНТАКТЫ И КОМПАНИИ
Полный доступ к базе клиентов. Быстрый поиск, звонки, отправка писем и просмотр связанных сделок в одно касание.

СДЕЛКИ И КАСТОМНЫЕ ОБЪЕКТЫ
Приложение адаптируется под вашу структуру CRM: просматривайте воронку продаж и динамические таблицы вашего сервера.

СКАНИРОВАНИЕ ВИЗИТОК
Наведите камеру на визитную карточку, и приложение автоматически считает имя, телефон, email и компанию прямо в CRM.

УМНЫЕ НАПОМИНАНИЯ
Устанавливайте сроки выполнения и получайте локальные уведомления, чтобы не пропустить важный контакт.

ОСОБЕННОСТИ:
• Контакты, Компании, Сделки, Задачи и Заметки
• Поддержка кастомных объектов Twenty CRM
• Распознавание текста визиток на устройстве
• Тёмная и светлая темы оформления
• Встроенный демо-режим для быстрого знакомства."""
    },
    "tr-TR": {
        "title": "TwentyMobile: Twenty CRM",
        "subtitle": "Sizin CRM'iniz, Veriniz",
        "short_description": "Twenty CRM için yerel mobil uygulama. Güvenli, gizli ve açık kaynak.",
        "keywords": "CRM,twenty,self-hosted,kisiler,satis,acik kaynak,lead,sirketler,tarayici,gorevler,musteri",
        "promotional_text": "Twenty CRM sunucunuza doğrudan bağlanın. %100 gizli, yerel ve açık kaynak.",
        "release_notes": "• Geliştirilmiş OAuth 2.0 PKCE ve SSO giriş desteği.\n• Twenty CRM senkronizasyon performansında artış.\n• Kartvizit tarayıcı optimizasyonları ve hızlı kayıt.\n• Kararlılık iyileştirmeleri ve arayüz güncellemeleri.\n",
        "full_description": """TwentyMobile — Sizin CRM'iniz, sizin veriniz.
Twenty CRM için geliştirilen ilk yerel mobil uygulama. Kendi barındırdığınız (self-hosted) sunucunuza doğrudan bağlanın, müşteri ilişkilerinizi ve satışlarınızı güvenle yönetin.

VERİLERİNİZ SİZİN KONTROLÜNÜZDE
TwentyMobile yalnızca kendi Twenty CRM sunucunuzla iletişim kurar. Üçüncü taraf aracı sunucular, veri takibi veya abonelik ücreti yoktur.

BUGÜN EKRANI — GÜNLÜK MERKEZİNİZ
Güne en önemli önceliklerinizle başlayın: Geciken görevler, bugünün işleri, yarının ajandası ve son kişiler tek bir ekranda.

KİŞİLER VE ŞİRKETLER
Çalışma alanınızdaki tüm standart ve özel tablolara erişin. Tek dokunuşla arayın, filtreleyin, arama yapın veya e-posta gönderin.

FIRSATLAR VE ÖZEL NESNELER
TwentyMobile iş akışınıza uyum sağlar: Satış fırsatlarını ve sunucunuzda tanımlı özel tabloları dinamik formlarla yönetin.

KARTVİZİT TARAYICI
Kameranızı herhangi bir basılı kartvizite doğrultun; isim, e-posta, telefon ve şirketi anında CRM'inize kaydedin.

AKILLI HATIRLATICILAR
Görevlerinize bitiş tarihi ekleyin ve yerel bildirimlerle hiçbir takibi kaçırmayın.

ÖNE ÇIKANLAR:
• Kişiler, Şirketler, Fırsatlar, Görevler ve Notlar
• Twenty CRM özel nesneleriyle tam uyum
• Cihaz üzerinde kartvizit metin tanıma
• Şık Karanlık ve Aydınlık tema desteği
• Kurulum yapmadan denemek için hazır demo modu."""
    }
}

# Write metadata files for each locale
for loc, fields in DATA.items():
    loc_dir = M / loc
    loc_dir.mkdir(parents=True, exist_ok=True)
    
    (loc_dir / "title.txt").write_text(fields["title"].strip() + "\n")
    (loc_dir / "subtitle.txt").write_text(fields["subtitle"].strip() + "\n")
    (loc_dir / "short_description.txt").write_text(fields["short_description"].strip() + "\n")
    (loc_dir / "full_description.txt").write_text(fields["full_description"].strip() + "\n")
    (loc_dir / "keywords.txt").write_text(fields["keywords"].strip() + "\n")
    (loc_dir / "promotional_text.txt").write_text(fields["promotional_text"].strip() + "\n")
    (loc_dir / "release_notes.txt").write_text(fields["release_notes"].strip() + "\n")
    
    # Changelogs for version code 46 and default
    cl_dir = loc_dir / "changelogs"
    cl_dir.mkdir(parents=True, exist_ok=True)
    (cl_dir / f"{ver_code}.txt").write_text(fields["release_notes"].strip() + "\n")
    (cl_dir / "default.txt").write_text(fields["release_notes"].strip() + "\n")

print(f"✅ Metadata multilingua e changelogs ({ver_code}) generati con successo per 9 lingue in {M}!")
