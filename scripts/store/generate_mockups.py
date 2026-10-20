#!/usr/bin/env python3
"""Genera mockup e grafiche multilingua per TwentyMobile (App Store Connect e Google Play).
Stile premium ispirato a SendToReader e personalizzato con palette Twenty CRM:
  - Sfondo scuro onice (#0B0C10 -> #131622) con glow blu elettrico (#4F8EF7) e cobalto (#2D6FD9)
  - Badge a pillola in vetro satinato con icona
  - Titoli ad alto contrasto con accento cromatico
  - Cornici dispositivi rifinite (iPhone con Dynamic Island, iPad, Phone, Tablet)
  - Slide 1..5: screenshot nativi Android per Android, iPhone/iPad per iOS
  - Slide 6: composizione multi-dispositivo con acquisizione e crop del biglietto da visita
             + verifica e creazione automatica del contatto nel CRM (OCR)

Output layout conforme a store-kit:
  store/screenshots/<locale>/
    android_phone/slide_1.png .. slide_6.png
    android_tablet_7/slide_1.png .. slide_6.png
    android_tablet_10/slide_1.png .. slide_6.png
    ios_iphone_6_5/slide_1.png .. slide_6.png
    ios_ipad_13/slide_1.png .. slide_6.png
    featureGraphic.png (1024x500)
    icon.png (512x512)
"""
import math
import os
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path("/Volumes/SSD 990 PRO/Developments/Works/pocketcrm")
IPHONE_RAW = ROOT / "assets/screenshot/iphone"
IPAD_RAW = ROOT / "assets/screenshot/ipad"
ANDROID_RAW = ROOT / "website/assets/img/screenshots"
ICON_RAW = ROOT / "assets/images/logo.png"
OUT_BASE = ROOT / "store/screenshots"

# 5 schermate singole per ciascun ambiente
IPHONE_SOURCES = [
    IPHONE_RAW / "Simulator Screenshot - iPhone 16 - 2026-04-15 at 20.49.23.png", # 1: Today Dashboard
    IPHONE_RAW / "Simulator Screenshot - iPhone 16 - 2026-04-15 at 20.49.33.png", # 2: Contacts & Leads
    IPHONE_RAW / "Simulator Screenshot - iPhone 16 - 2026-04-15 at 20.50.05.png", # 3: Companies & Pipeline
    IPHONE_RAW / "Simulator Screenshot - iPhone 16 - 2026-04-15 at 20.50.29.png", # 4: Tasks & Follow-ups
    IPHONE_RAW / "Simulator Screenshot - iPhone 16 - 2026-04-15 at 20.50.18.png", # 5: CRM Card & Quick Details
]

IPAD_SOURCES = [
    IPAD_RAW / "Simulator Screenshot - iPad Pro 13-inch (M4) - 2026-04-15 at 21.04.43.png", # 1: Today Dashboard
    IPAD_RAW / "Simulator Screenshot - iPad Pro 13-inch (M4) - 2026-04-15 at 21.04.57.png", # 2: Contacts & Leads
    IPAD_RAW / "Simulator Screenshot - iPad Pro 13-inch (M4) - 2026-04-15 at 21.05.01.png", # 3: Companies & Pipeline
    IPAD_RAW / "Simulator Screenshot - iPad Pro 13-inch (M4) - 2026-04-15 at 21.05.05.png", # 4: Tasks & Follow-ups
    IPAD_RAW / "Simulator Screenshot - iPad Pro 13-inch (M4) - 2026-04-15 at 21.05.11.png", # 5: CRM Card & Quick Details
]

ANDROID_SOURCES = [
    ANDROID_RAW / "Screenshot_20260326-115125.png", # 1: Today Dashboard
    ANDROID_RAW / "Screenshot_20260326-115135.png", # 2: Contacts & Leads
    ANDROID_RAW / "Screenshot_20260326-115155.png", # 3: Companies & Pipeline
    ANDROID_RAW / "Screenshot_20260326-115205.png", # 4: Tasks & Follow-ups
    ANDROID_RAW / "Screenshot_20260326-115316.png", # 5: Quick Actions & Twenty Direct Connect
]

# Slide 6: Biglietti da Visita & Creazione Automatica Contatti (2 immagini combinate)
CARD_SCAN_RAW = ANDROID_RAW / "Screenshot_20260326-115419.png" # Crop business card
CARD_FORM_RAW = ANDROID_RAW / "Screenshot_20260326-115434.png" # Verify data / Create contact

LOCALES = ["en-US", "it-IT", "es-ES", "fr-FR", "de-DE", "pt-BR", "pl-PL", "ru-RU", "tr-TR"]

COPY = {
    "en-US": {
        "slides": [
            {
                "badge": "TODAY DASHBOARD",
                "title": "Your Daily CRM HQ",
                "subtitle": "Track overdue tasks, today's schedule\nand recent contacts at a single glance."
            },
            {
                "badge": "CONTACTS & LEADS",
                "title": "Manage Relationships",
                "subtitle": "Search, filter and connect with leads\nwith one-tap calling and quick actions."
            },
            {
                "badge": "COMPANIES PIPELINE",
                "title": "Organize Accounts",
                "subtitle": "Navigate companies, linked stakeholders\nand workspace accounts effortlessly."
            },
            {
                "badge": "TASKS & REMINDERS",
                "title": "Never Miss a Deadline",
                "subtitle": "Intelligent task follow-ups with local\nnotifications before every due date."
            },
            {
                "badge": "SELF-HOSTED FREEDOM",
                "title": "100% Private CRM",
                "subtitle": "Connect directly to your Twenty instance.\nZero trackers, open source and secure."
            },
            {
                "badge": "AI CARD SCANNER",
                "title": "Scan & Auto-Create",
                "subtitle": "Capture paper business cards and create\nCRM contacts automatically with OCR."
            }
        ],
        "fg_title": "TwentyMobile",
        "fg_sub": "Your CRM, Your Data",
        "fg_badge": "Self-Hosted • 100% Private • Open Source"
    },
    "it-IT": {
        "slides": [
            {
                "badge": "DASHBOARD OGGI",
                "title": "Il tuo Quartier Generale",
                "subtitle": "Attività in scadenza, priorità del giorno\ne contatti recenti sempre in primo piano."
            },
            {
                "badge": "CONTATTI & LEAD",
                "title": "Gestione Relazioni",
                "subtitle": "Cerca, filtra e comunica con i lead\ncon chiamate rapide e note istantanee."
            },
            {
                "badge": "AZIENDE & ACCOUNT",
                "title": "Organizza le Aziende",
                "subtitle": "Visualizza schede societarie, persone\ncollegate e pipeline commerciale."
            },
            {
                "badge": "ATTIVITÀ & SCADENZE",
                "title": "Zero Follow-up Persi",
                "subtitle": "Pianifica le tue attività con promemoria\nintelligenti prima della scadenza."
            },
            {
                "badge": "SELF-HOSTED FREEDOM",
                "title": "100% Privacy e Controllo",
                "subtitle": "Collegamento diretto alla tua istanza Twenty.\nNessun intermediario, open source e sicuro."
            },
            {
                "badge": "SCANNER BIGLIETTI",
                "title": "Scansiona & Crea Subito",
                "subtitle": "Inquadra biglietti da visita cartacei e crea\ncontatti nel CRM con riconoscimento OCR."
            }
        ],
        "fg_title": "TwentyMobile",
        "fg_sub": "Il tuo CRM, i tuoi dati",
        "fg_badge": "Self-Hosted • 100% Privato • Open Source"
    },
    "es-ES": {
        "slides": [
            {
                "badge": "PANEL DIARIO",
                "title": "Tu Centro de Control",
                "subtitle": "Tareas pendientes, prioridades del día\ny contactos recientes en un solo lugar."
            },
            {
                "badge": "CONTACTOS Y LEADS",
                "title": "Gestión de Relaciones",
                "subtitle": "Busca, filtra y contacta con clientes\ncon llamadas y notas al instante."
            },
            {
                "badge": "EMPRESAS Y CUENTAS",
                "title": "Organiza tus Empresas",
                "subtitle": "Visualiza perfiles completos, personas\nvinculadas y oportunidades activas."
            },
            {
                "badge": "TAREAS Y RECORDATORIOS",
                "title": "Cumple cada Plazo",
                "subtitle": "Seguimiento inteligente con notificaciones\nlocales antes de cada vencimiento."
            },
            {
                "badge": "TOTAL PRIVACIDAD",
                "title": "CRM 100% Autoalojado",
                "subtitle": "Conexión directa a tu servidor Twenty.\nSin intermediarios, seguro y de código abierto."
            },
            {
                "badge": "ESCÁNER DE TARJETAS",
                "title": "Escanea y Crea Contactos",
                "subtitle": "Captura tarjetas de visita y crea contactos\nen Twenty CRM al instante con OCR."
            }
        ],
        "fg_title": "TwentyMobile",
        "fg_sub": "Tu CRM, tus propios datos",
        "fg_badge": "Self-Hosted • 100% Privado • Open Source"
    },
    "fr-FR": {
        "slides": [
            {
                "badge": "TABLEAU DE BORD",
                "title": "Votre QG Quotidien",
                "subtitle": "Tâches en retard, priorités du jour\net contacts récents d'un coup d'œil."
            },
            {
                "badge": "CONTACTS & PROSPECTS",
                "title": "Gérez vos Relations",
                "subtitle": "Recherchez, filtrez et contactez vos leads\navec appels et emails en un clic."
            },
            {
                "badge": "ENTREPRISES & COMPTES",
                "title": "Organisez vos Entreprises",
                "subtitle": "Suivez les comptes d'entreprises, les\ninterlocuteurs clés et vos affaires."
            },
            {
                "badge": "TÂCHES ET RAPPELS",
                "title": "Ne Manquez Aucun Délai",
                "subtitle": "Planification intelligente avec rappels\nlocaux avant chaque échéance."
            },
            {
                "badge": "LIBERTÉ SELF-HOSTED",
                "title": "CRM 100% Privé",
                "subtitle": "Connexion directe à votre instance Twenty.\nZéro traceur, sécurisé et open source."
            },
            {
                "badge": "SCANNER DE CARTES",
                "title": "Numérisez & Créez",
                "subtitle": "Scannez des cartes de visite et créez des\ncontacts dans Twenty CRM grâce à l'OCR."
            }
        ],
        "fg_title": "TwentyMobile",
        "fg_sub": "Votre CRM, vos données",
        "fg_badge": "Self-Hosted • 100% Privé • Open Source"
    },
    "de-DE": {
        "slides": [
            {
                "badge": "HEUTE-DASHBOARD",
                "title": "Deine CRM-Zentrale",
                "subtitle": "Fällige Aufgaben, Tagesprioritäten und\naktuelle Kontakte sofort im Überblick."
            },
            {
                "badge": "KONTAKTE & LEADS",
                "title": "Beziehungen Managen",
                "subtitle": "Leads schnell filtern, anrufen und\nwichtige Notizen sofort festhalten."
            },
            {
                "badge": "UNTERNEHMEN & KONTEN",
                "title": "Firmen Organisieren",
                "subtitle": "Unternehmensprofile, Ansprechpartner\nund Vertriebschancen sauber verknüpfen."
            },
            {
                "badge": "AUFGABEN & FRISTEN",
                "title": "Keine Frist Verpassen",
                "subtitle": "Intelligente Erinnerungen mit lokalen\nPush-Benachrichtigungen vor Fälligkeit."
            },
            {
                "badge": "SELF-HOSTED FREIHEIT",
                "title": "100% Private Daten",
                "subtitle": "Direkte Verbindung zu deinem Twenty CRM.\nKeine Tracker, sicher und Open Source."
            },
            {
                "badge": "VISITENKARTEN-SCANNER",
                "title": "Scannen & Erstellen",
                "subtitle": "Visitenkarten erfassen und Kontakte\nsofort per OCR in Twenty CRM anlegen."
            }
        ],
        "fg_title": "TwentyMobile",
        "fg_sub": "Dein CRM, deine Daten",
        "fg_badge": "Self-Hosted • 100% Privat • Open Source"
    },
    "pt-BR": {
        "slides": [
            {
                "badge": "PAINEL HOJE",
                "title": "Seu QG Diário",
                "subtitle": "Tarefas atrasadas, prioridades do dia\ne contatos recentes em foco total."
            },
            {
                "badge": "CONTATOS E LEADS",
                "title": "Gestão de Relacionamento",
                "subtitle": "Pesquise, filtre e conecte-se com clientes\ncom ligações e notas rápidas."
            },
            {
                "badge": "EMPRESAS E CONTAS",
                "title": "Organize Empresas",
                "subtitle": "Acompanhe perfis empresariais, sócios\ne histórico comercial sem esforço."
            },
            {
                "badge": "TAREFAS E LEMBRETES",
                "title": "Prazos Sempre em Dia",
                "subtitle": "Lembretes inteligentes com notificações\nlocais antes de cada vencimento."
            },
            {
                "badge": "LIBERDADE SELF-HOSTED",
                "title": "CRM 100% Privado",
                "subtitle": "Conexão direta ao seu servidor Twenty.\nSem intermediários e código aberto."
            },
            {
                "badge": "SCANNER DE CARTÕES",
                "title": "Escanear & Criar",
                "subtitle": "Digitalize cartões de visita e crie contatos\nno Twenty CRM instantaneamente via OCR."
            }
        ],
        "fg_title": "TwentyMobile",
        "fg_sub": "Seu CRM, seus dados",
        "fg_badge": "Self-Hosted • 100% Privado • Open Source"
    },
    "pl-PL": {
        "slides": [
            {
                "badge": "PANEL DZISIAJ",
                "title": "Twoje Centrum Dowodzenia",
                "subtitle": "Zaległe zadania, dzisiejsze priorytety\ni ostatnie kontakty w zasięgu ręki."
            },
            {
                "badge": "KONTAKTY I LEADY",
                "title": "Zarządzanie Relacjami",
                "subtitle": "Wyszukuj, filtruj i kontaktuj się z leadami\nza pomocą szybkich połączeń i notatek."
            },
            {
                "badge": "FIRMY I KONTA",
                "title": "Organizuj Firmy",
                "subtitle": "Przeglądaj profile spółek, osoby powiązane\noraz aktywny pipeline sprzedaży."
            },
            {
                "badge": "ZADANIA I TERMINY",
                "title": "Zawsze na Czas",
                "subtitle": "Inteligentne planowanie z powiadomieniami\nprzed nadejściem terminu zadania."
            },
            {
                "badge": "PEŁNA PRYWATNOŚĆ",
                "title": "100% Self-Hosted CRM",
                "subtitle": "Bezpośrednie połączenie z Twoim Twenty CRM.\nBez pośredników, bezpiecznie i open source."
            },
            {
                "badge": "SKANER WIZYTÓWEK",
                "title": "Skanuj i Utwórz",
                "subtitle": "Skanuj wizytówki i twórz kontakty\nw Twenty CRM automatycznie przez OCR."
            }
        ],
        "fg_title": "TwentyMobile",
        "fg_sub": "Twój CRM, Twoje dane",
        "fg_badge": "Self-Hosted • 100% Prywatności • Open Source"
    },
    "ru-RU": {
        "slides": [
            {
                "badge": "ЭКРАН СЕГОДНЯ",
                "title": "Ваш Центр Управления",
                "subtitle": "Просроченные дела, задачи на сегодня\nи недавние контакты в одном месте."
            },
            {
                "badge": "КОНТАКТЫ И ЛИДЫ",
                "title": "Управление Клиентами",
                "subtitle": "Поиск, фильтрация и быстрая связь\nс лидами в одно касание."
            },
            {
                "badge": "КОМПАНИИ И СДЕЛКИ",
                "title": "Организация Компаний",
                "subtitle": "Просматривайте профили организаций,\nключевых лиц и воронку продаж."
            },
            {
                "badge": "ЗАДАЧИ И НАПОМИНАНИЯ",
                "title": "Все Сроки под Контролем",
                "subtitle": "Умные напоминания с локальными\nуведомлениями до дедлайна."
            },
            {
                "badge": "ПОЛНАЯ ПРИВАТНОСТЬ",
                "title": "100% Self-Hosted CRM",
                "subtitle": "Прямое подключение к вашему Twenty CRM.\nБез трекеров, безопасно и открытый код."
            },
            {
                "badge": "СКАНЕР ВИЗИТОК",
                "title": "Сканируйте и создавайте",
                "subtitle": "Сканируйте визитки и мгновенно\nсоздавайте контакты в Twenty CRM с OCR."
            }
        ],
        "fg_title": "TwentyMobile",
        "fg_sub": "Ваша CRM, ваши данные",
        "fg_badge": "Self-Hosted • 100% Приватно • Open Source"
    },
    "tr-TR": {
        "slides": [
            {
                "badge": "BUGÜN PANELİ",
                "title": "Günlük Kontrol Merkeziniz",
                "subtitle": "Geciken işler, bugünün öncelikleri ve\nson kişiler tek bakışta karşınızda."
            },
            {
                "badge": "KİŞİLER VE LEADLER",
                "title": "Müşteri İlişkileri",
                "subtitle": "Kişileri kolayca arayın, filtreleyin ve\nhızlı aramalarla anında iletişime geçin."
            },
            {
                "badge": "ŞİRKETLER VE HESAPLAR",
                "title": "Şirketleri Organize Edin",
                "subtitle": "Kurumsal profilleri, ilişkili kişileri\nve satış fırsatlarını tek yerden yönetin."
            },
            {
                "badge": "GÖREVLER VE TAKİP",
                "title": "Tüm Teslim Tarihleri Güvende",
                "subtitle": "Bitiş tarihinden önce gelen yerel\nbildirimlerle hiçbir takibi kaçırmayın."
            },
            {
                "badge": "GİZLİLİK VE ÖZGÜRLÜK",
                "title": "%100 Özel Twenty CRM",
                "subtitle": "Kendi Twenty CRM sunucunuza doğrudan bağlanın.\nAracı yok, güvenli ve açık kaynak."
            },
            {
                "badge": "KARTVİZİT TARAYICI",
                "title": "Tara ve Otomatik Ekle",
                "subtitle": "Kartvizitleri tarayın ve OCR ile\nTwenty CRM içinde anında kişi oluşturun."
            }
        ],
        "fg_title": "TwentyMobile",
        "fg_sub": "Sizin CRM'iniz, Veriniz",
        "fg_badge": "Self-Hosted • %100 Gizli • Açık Kaynak"
    }
}

PROFILES = {
    "android_phone": {
        "canvas_w": 1080, "canvas_h": 1920, "target_w": 820,
        "badge_y": 140, "title_y": 230, "sub_y": 345, "sub_lh": 55, "frame_y": 550,
        "badge_size": 26, "title_size": 68, "sub_size": 38,
        "frame_radius": 52, "screenshot_radius": 42,
        "is_ios": False, "is_tablet": False
    },
    "android_tablet_7": {
        "canvas_w": 1200, "canvas_h": 1920, "target_w": 960,
        "badge_y": 140, "title_y": 230, "sub_y": 345, "sub_lh": 55, "frame_y": 550,
        "badge_size": 28, "title_size": 74, "sub_size": 42,
        "frame_radius": 52, "screenshot_radius": 42,
        "is_ios": False, "is_tablet": True
    },
    "android_tablet_10": {
        "canvas_w": 1600, "canvas_h": 2560, "target_w": 1280,
        "badge_y": 190, "title_y": 310, "sub_y": 460, "sub_lh": 75, "frame_y": 750,
        "badge_size": 38, "title_size": 100, "sub_size": 56,
        "frame_radius": 70, "screenshot_radius": 56,
        "is_ios": False, "is_tablet": True
    },
    "ios_iphone_6_5": {
        "canvas_w": 1284, "canvas_h": 2778, "target_w": 1040,
        "badge_y": 220, "title_y": 330, "sub_y": 490, "sub_lh": 75, "frame_y": 800,
        "badge_size": 34, "title_size": 94, "sub_size": 50,
        "frame_radius": 84, "screenshot_radius": 68,
        "is_ios": True, "is_tablet": False
    },
    "ios_ipad_13": {
        "canvas_w": 2048, "canvas_h": 2732, "target_w": 1420,
        "badge_y": 190, "title_y": 310, "sub_y": 480, "sub_lh": 85, "frame_y": 830,
        "badge_size": 44, "title_size": 120, "sub_size": 65,
        "frame_radius": 88, "screenshot_radius": 70,
        "is_ios": False, "is_tablet": True
    }
}


def get_font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf"
    ]
    for p in candidates:
        if os.path.exists(p):
            try:
                idx = 1 if (bold and p.endswith(".ttc")) else 0
                return ImageFont.truetype(p, size, index=idx)
            except Exception:
                try:
                    return ImageFont.truetype(p, size)
                except Exception:
                    continue
    return ImageFont.load_default()


def create_twenty_gradient(w, h):
    """Crea uno sfondo deep onyx con sfumature e bagliori radiali blu elettrico / cobalto."""
    base = Image.new("RGBA", (w, h), (11, 12, 16, 255))
    
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    
    # 1. Top electric blue glow (#4F8EF7)
    cx1, cy1 = int(w * 0.75), int(h * 0.12)
    r1 = int(min(w, h) * 0.65)
    for rad in range(r1, 0, -8):
        alpha = int(45 * (1.0 - rad / r1) ** 1.8)
        g_draw.ellipse([cx1 - rad, cy1 - rad, cx1 + rad, cy1 + rad], fill=(79, 142, 247, alpha))
        
    # 2. Bottom cobalt/purple glow (#2D6FD9 / #6366F1)
    cx2, cy2 = int(w * 0.20), int(h * 0.88)
    r2 = int(min(w, h) * 0.70)
    for rad in range(r2, 0, -8):
        alpha = int(40 * (1.0 - rad / r2) ** 1.8)
        g_draw.ellipse([cx2 - rad, cy2 - rad, cx2 + rad, cy2 + rad], fill=(45, 111, 217, alpha))
        
    base = Image.alpha_composite(base, glow)
    return base.convert("RGB")


def add_rounded_corners(im, rad):
    circle = Image.new('L', (rad * 2, rad * 2), 0)
    draw = ImageDraw.Draw(circle)
    draw.ellipse((0, 0, rad * 2 - 1, rad * 2 - 1), fill=255)
    alpha = Image.new('L', im.size, 255)
    w, h = im.size
    alpha.paste(circle.crop((0, 0, rad, rad)), (0, 0))
    alpha.paste(circle.crop((0, rad, rad, rad * 2)), (0, h - rad))
    alpha.paste(circle.crop((rad, 0, rad * 2, rad)), (w - rad, 0))
    alpha.paste(circle.crop((rad, rad, rad * 2, rad * 2)), (w - rad, h - rad))
    im.putalpha(alpha)
    return im


def draw_iphone_bezel_decorations(draw, frame_w, frame_thickness):
    island_w = int(frame_w * 0.28)
    island_h = int(frame_thickness * 1.8)
    island_x = (frame_w - island_w) // 2
    island_y = frame_thickness + 12
    draw.rounded_rectangle([island_x, island_y, island_x + island_w, island_y + island_h], radius=island_h//2, fill=(0, 0, 0, 255))
    
    draw.rounded_rectangle([frame_w - 3, 260, frame_w, 420], radius=2, fill=(90, 95, 105, 255))
    draw.rounded_rectangle([0, 220, 3, 310], radius=2, fill=(90, 95, 105, 255))
    draw.rounded_rectangle([0, 330, 3, 430], radius=2, fill=(90, 95, 105, 255))


def render_headers(canvas, cfg_profile, text_data):
    """Renderizza badge, titolo e sottotitolo comuni."""
    w = cfg_profile["canvas_w"]
    h = cfg_profile["canvas_h"]
    draw = ImageDraw.Draw(canvas)
    
    # 1. Badge
    badge_text = text_data["badge"].upper()
    b_font = get_font(cfg_profile["badge_size"], bold=True)
    b_bbox = draw.textbbox((0, 0), badge_text, font=b_font)
    b_text_w = b_bbox[2] - b_bbox[0]
    b_text_h = b_bbox[3] - b_bbox[1]
    
    pad_h = int(cfg_profile["badge_size"] * 0.8)
    pad_v = int(cfg_profile["badge_size"] * 0.35)
    pill_w = b_text_w + pad_h * 2
    pill_h = b_text_h + pad_v * 2
    pill_x = (w - pill_w) // 2
    pill_y = cfg_profile["badge_y"]
    
    pill_overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    p_draw = ImageDraw.Draw(pill_overlay)
    p_draw.rounded_rectangle(
        [pill_x, pill_y, pill_x + pill_w, pill_y + pill_h],
        radius=pill_h // 2,
        fill=(79, 142, 247, 40),
        outline=(96, 165, 250, 140),
        width=max(2, int(w * 0.002))
    )
    canvas.paste(pill_overlay, (0, 0), pill_overlay)
    
    draw = ImageDraw.Draw(canvas)
    draw.text((pill_x + pad_h, pill_y + pad_v - 2), badge_text, font=b_font, fill=(96, 165, 250))
    
    # 2. Titolo
    title_text = text_data["title"]
    t_font = get_font(cfg_profile["title_size"], bold=True)
    t_bbox = draw.textbbox((0, 0), title_text, font=t_font)
    t_w = t_bbox[2] - t_bbox[0]
    draw.text(((w - t_w) // 2, cfg_profile["title_y"]), title_text, font=t_font, fill=(255, 255, 255))
    
    # 3. Sottotitolo
    sub_lines = text_data["subtitle"].split("\n")
    s_font = get_font(cfg_profile["sub_size"], bold=False)
    for i, line in enumerate(sub_lines):
        s_bbox = draw.textbbox((0, 0), line, font=s_font)
        s_w = s_bbox[2] - s_bbox[0]
        line_y = cfg_profile["sub_y"] + i * cfg_profile["sub_lh"]
        draw.text(((w - s_w) // 2, line_y), line, font=s_font, fill=(161, 161, 170))


def render_mockup(cfg_profile, slide_idx, text_data, raw_screen_path, out_file):
    w = cfg_profile["canvas_w"]
    h = cfg_profile["canvas_h"]
    canvas = create_twenty_gradient(w, h)
    render_headers(canvas, cfg_profile, text_data)
    
    # Schermo & Cornice
    raw_img = Image.open(raw_screen_path).convert("RGBA")
    target_w = cfg_profile["target_w"]
    aspect = raw_img.height / raw_img.width
    target_h = int(target_w * aspect)
    resized_screen = raw_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    scr_radius = cfg_profile["screenshot_radius"]
    rounded_screen = add_rounded_corners(resized_screen, scr_radius)
    
    thickness = max(14, int(target_w * 0.022))
    frame_w = target_w + thickness * 2
    frame_h = target_h + thickness * 2
    frame_rad = cfg_profile["frame_radius"]
    
    frame_img = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    f_draw = ImageDraw.Draw(frame_img)
    f_draw.rounded_rectangle(
        [0, 0, frame_w, frame_h],
        radius=frame_rad,
        fill=(24, 26, 34, 255),
        outline=(56, 60, 74, 255),
        width=max(3, int(w * 0.003))
    )
    
    if cfg_profile["is_ios"]:
        draw_iphone_bezel_decorations(f_draw, frame_w, thickness)
        
    frame_img.paste(rounded_screen, (thickness, thickness), rounded_screen)
    
    # Home Indicator
    home_w = int(target_w * 0.35)
    home_h = max(4, int(thickness * 0.35))
    home_x = (frame_w - home_w) // 2
    home_y = frame_h - thickness - int(home_h * 2.5)
    f_draw.rounded_rectangle([home_x, home_y, home_x + home_w, home_y + home_h], radius=home_h//2, fill=(255, 255, 255, 180))
    
    # Ombra
    shadow = Image.new("RGBA", (frame_w + 100, frame_h + 100), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(shadow)
    sh_draw.rounded_rectangle([50, 50, frame_w + 50, frame_h + 50], radius=frame_rad, fill=(0, 0, 0, 160))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=35))
    
    pos_x = (w - frame_w) // 2
    pos_y = cfg_profile["frame_y"]
    
    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.paste(shadow, (pos_x - 50, pos_y - 30), shadow)
    canvas_rgba.paste(frame_img, (pos_x, pos_y), frame_img)
    
    out_file.parent.mkdir(parents=True, exist_ok=True)
    canvas_rgba.convert("RGB").save(out_file, "PNG", optimize=True)


def render_dual_mockup(cfg_profile, slide_idx, text_data, raw_screen_left, raw_screen_right, out_file):
    """Renderizza una composizione a doppio dispositivo per la Slide 6 (Biglietti da visita + Contatto)."""
    w = cfg_profile["canvas_w"]
    h = cfg_profile["canvas_h"]
    canvas = create_twenty_gradient(w, h)
    render_headers(canvas, cfg_profile, text_data)
    
    scale = 0.65 if not cfg_profile["is_tablet"] else 0.52
    single_w = int(cfg_profile["target_w"] * scale)
    
    def build_frame(raw_path):
        raw_img = Image.open(raw_path).convert("RGBA")
        aspect = raw_img.height / raw_img.width
        sw = single_w
        sh = int(sw * aspect)
        resized = raw_img.resize((sw, sh), Image.Resampling.LANCZOS)
        
        scr_rad = int(cfg_profile["screenshot_radius"] * scale)
        frame_rad = int(cfg_profile["frame_radius"] * scale)
        rounded_scr = add_rounded_corners(resized, scr_rad)
        
        thick = max(10, int(sw * 0.024))
        fw = sw + thick * 2
        fh = sh + thick * 2
        
        f_img = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        fd = ImageDraw.Draw(f_img)
        fd.rounded_rectangle([0, 0, fw, fh], radius=frame_rad, fill=(24, 26, 34, 255), outline=(56, 60, 74, 255), width=max(2, int(w * 0.002)))
        
        if cfg_profile["is_ios"]:
            iw = int(fw * 0.28)
            ih = int(thick * 1.8)
            fd.rounded_rectangle([(fw - iw)//2, thick + 8, (fw + iw)//2, thick + 8 + ih], radius=ih//2, fill=(0, 0, 0, 255))
            
        f_img.paste(rounded_scr, (thick, thick), rounded_scr)
        
        hw = int(sw * 0.35)
        hh = max(3, int(thick * 0.35))
        fd.rounded_rectangle([(fw - hw)//2, fh - thick - int(hh*2), (fw + hw)//2, fh - thick - hh], radius=hh//2, fill=(255, 255, 255, 180))
        return f_img

    dev_left = build_frame(raw_screen_left)
    dev_right = build_frame(raw_screen_right)
    
    # Ombre
    sh_l = Image.new("RGBA", (dev_left.width + 60, dev_left.height + 60), (0, 0, 0, 0))
    ImageDraw.Draw(sh_l).rounded_rectangle([30, 30, dev_left.width + 30, dev_left.height + 30], radius=35, fill=(0, 0, 0, 140))
    sh_l = sh_l.filter(ImageFilter.GaussianBlur(radius=25))
    
    sh_r = Image.new("RGBA", (dev_right.width + 80, dev_right.height + 80), (0, 0, 0, 0))
    ImageDraw.Draw(sh_r).rounded_rectangle([40, 40, dev_right.width + 40, dev_right.height + 40], radius=40, fill=(0, 0, 0, 190))
    sh_r = sh_r.filter(ImageFilter.GaussianBlur(radius=30))
    
    if cfg_profile["is_tablet"]:
        left_x = int(w * 0.16)
        right_x = int(w * 0.50)
        left_y = cfg_profile["frame_y"] + int(h * 0.02)
        right_y = cfg_profile["frame_y"]
    else:
        left_x = int(w * 0.07)
        right_x = int(w * 0.41)
        left_y = cfg_profile["frame_y"] + int(h * 0.035)
        right_y = cfg_profile["frame_y"]
        
    canvas_rgba = canvas.convert("RGBA")
    
    # Posiziona Dispositivo Sinistro (Crop Biglietto)
    canvas_rgba.paste(sh_l, (left_x - 30, left_y - 20), sh_l)
    canvas_rgba.paste(dev_left, (left_x, left_y), dev_left)
    
    # Posiziona Dispositivo Destro (Verifica e Crea Contatto in primo piano)
    canvas_rgba.paste(sh_r, (right_x - 40, right_y - 25), sh_r)
    canvas_rgba.paste(dev_right, (right_x, right_y), dev_right)
    
    out_file.parent.mkdir(parents=True, exist_ok=True)
    canvas_rgba.convert("RGB").save(out_file, "PNG", optimize=True)


def generate_feature_graphic(loc_dir, copy_item, icon_src):
    """Feature Graphic Google Play 1024x500 pulita e minimale in stile Twenty CRM."""
    w, h = 1024, 500
    fg = create_twenty_gradient(w, h)
    
    # Pulizia perfetta dell'icona: elimina bordi bianchi esterni tramite maschera pulita
    icon_master = Image.open(icon_src).convert("RGBA")
    mask = Image.new("L", icon_master.size, 0)
    m_draw = ImageDraw.Draw(mask)
    inset = 14
    rad = int((icon_master.width - inset * 2) * 0.22)
    m_draw.rounded_rectangle(
        [inset, inset, icon_master.width - inset, icon_master.height - inset],
        radius=rad, fill=255
    )
    icon_clean = Image.new("RGBA", icon_master.size, (0, 0, 0, 0))
    icon_clean.paste(icon_master, (0, 0), mask)
    
    icon_sz = 210
    icon_img = icon_clean.resize((icon_sz, icon_sz), Image.Resampling.LANCZOS)
    icon_pos = (85, 145)
    
    fg_rgba = fg.convert("RGBA")
    # Incolla l'icona pura e pulita: nessun contorno blu, nessuna ombra nera/alone
    fg_rgba.paste(icon_img, icon_pos, icon_img)
    draw = ImageDraw.Draw(fg_rgba)
    
    # Blocco testi centrato più in alto, allineato con la sommità del logo
    tx = 335
    
    # 1. Titolo "TwentyMobile" (grande, bianco brillante, posizionato più in alto)
    t_font = get_font(68, bold=True)
    draw.text((tx, 145), copy_item["fg_title"], font=t_font, fill=(255, 255, 255))
    
    # 2. Sottotitolo
    s_font = get_font(32, bold=False)
    draw.text((tx, 230), copy_item["fg_sub"], font=s_font, fill=(203, 213, 225))
    
    # 3. Punti chiave (privato, self-hosted, open source)
    f_font = get_font(22, bold=True)
    draw.text((tx, 290), copy_item["fg_badge"], font=f_font, fill=(96, 165, 250))
    
    out_png = loc_dir / "featureGraphic.png"
    fg_rgba.convert("RGB").save(out_png, "PNG", optimize=True)


def main():
    print("🎨 Generazione Mockup TwentyMobile (Pillow puro) — 6 slide per dispositivo...")
    
    total_imgs = 0
    for loc in LOCALES:
        loc_dir = OUT_BASE / loc
        loc_dir.mkdir(parents=True, exist_ok=True)
        loc_copy = COPY[loc]
        print(f"\n🌍 Locale: {loc}")
        
        # 1. Feature Graphic (1024x500)
        generate_feature_graphic(loc_dir, loc_copy, ICON_RAW)
        total_imgs += 1
        
        # 2. App Icon (512x512)
        icon_dest = loc_dir / "icon.png"
        icon_master = Image.open(ICON_RAW).convert("RGBA").resize((512, 512), Image.Resampling.LANCZOS)
        icon_master.save(icon_dest, "PNG")
        total_imgs += 1
        
        # 3. Le 6 slide per ciascuno dei 5 profili dispositivo
        for prof_name, prof_cfg in PROFILES.items():
            # Scelta screenshot nativi: iPad per iPad, iPhone per iPhone, Android per Android
            if prof_cfg["is_ios"]:
                single_sources = IPHONE_SOURCES
            elif prof_cfg["is_tablet"]:
                single_sources = IPAD_SOURCES
            else:
                single_sources = ANDROID_SOURCES
                
            # Slide 1..5: Schermo singolo
            for s_idx in range(5):
                s_copy = loc_copy["slides"][s_idx]
                raw_path = single_sources[s_idx]
                out_path = loc_dir / prof_name / f"slide_{s_idx + 1}.png"
                render_mockup(prof_cfg, s_idx, s_copy, raw_path, out_path)
                total_imgs += 1
                
            # Slide 6: Biglietti da Visita & Auto Creazione Contatti (Composizione doppia)
            s_copy_6 = loc_copy["slides"][5]
            out_path_6 = loc_dir / prof_name / "slide_6.png"
            render_dual_mockup(prof_cfg, 5, s_copy_6, CARD_SCAN_RAW, CARD_FORM_RAW, out_path_6)
            total_imgs += 1
            
            print(f"  ✓ {prof_name} (6 slide)")
            
    print(f"\n🎉 Generazione completata con successo! Totale immagini create: {total_imgs} in {OUT_BASE}")


if __name__ == "__main__":
    main()
