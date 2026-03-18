# Dreamware KI-Plattform — Design Spec

**Datum:** 2026-03-18
**Status:** Approved
**Autor:** Dreamware / Claude Code Brainstorming Session

---

## 1. Produkt-Vision & Positionierung

**Produktname:** Dreamware KI-Plattform (basierend auf AnythingLLM Fork)

**Zielgruppe:** Anwaltskanzleien, Steuerberatungen, Datenschutzfirmen im DACH-Raum

**Kern-USP:**
DSGVO-konforme KI-Plattform mit branchenspezifischen Workflows — 100% EU-Hosting, Single-Tenant-Architektur, vollständiger Audit-Trail.

**Delivery-Modell:**
- **SaaS (primär):** Dreamware hostet auf Hetzner EU, Kunden bekommen dedizierte Instanz
- **On-Premise (sekundär):** Enterprise-Option für Kunden mit eigener Infrastruktur

**AI-Backend:**
- Mistral AI (primär — französisches Unternehmen, EU-DSGVO-konform)
- Azure OpenAI EU-Region (sekundär — für Kunden die Microsoft bevorzugen)
- Explizite Warnung in der UI wenn Nutzer US-basierte Provider konfigurieren möchten

---

## 2. Architektur

### Single-Tenant Deployment

Jeder Kunde erhält eine vollständig isolierte Docker-Instanz:
- Eigene PostgreSQL-Datenbank
- Eigener File-Storage (Hetzner Volume)
- Eigene Subdomain: `{kunde}.dreamware.at` (Custom Domain optional)
- Keine gemeinsame Infrastruktur zwischen Kunden

**Provisioning (Phase 1):** Semi-manuell via Skript (`infra/provision.sh`)
**Provisioning (Phase 2):** Automatisiertes Customer-Dashboard

### Datenhaltung & Sicherheit

- Storage auf Hetzner EU-Servern (Deutschland/Finnland)
- Verschlüsselung at-rest via Hetzner Volume Encryption
- Verschlüsselung in-transit via TLS (Caddy, bereits konfiguriert)
- Tägliche Backups, 30 Tage Retention, EU-Region

### Audit-Logging

- Jede KI-Anfrage wird geloggt: User-ID, Zeitstempel, Workspace, Modell, Tokenzahl
- **Kein Logging des Anfrage-Inhalts** (Mandatsgeheimnis / Berufsgeheimnis)
- Logs exportierbar als CSV/PDF für Compliance-Nachweise
- Aufbewahrungspflicht konfigurierbar (Standard: 12 Monate)

---

## 3. Roadmap & Milestones

### M0 — Compliance Foundation
*Ziel: DSGVO-Basis steht, erstes Verkaufsargument greifbar*

- EU AI Provider Integration (Mistral AI als Default)
- Audit-Logging System (Metadaten, kein Inhalt)
- Datenschutzerklärung & AVV-Vorlage für Kunden
- DSGVO-Checkliste / Compliance-Übersicht in der UI
- Warnung bei Konfiguration von Non-EU Providern
- Security: multer CVE + Dependabot-Backlog beheben (läuft bereits als Issue #34)

### M1 — Anwaltskanzlei MVP
*Ziel: Erste zahlende Referenzkunden aus Anwaltskanzleien*

- Workspace-Isolation pro Mandat (Dokumente nie mandatsübergreifend)
- Rollenmodell: Partner / Anwalt / Sekretariat
- Prompt-Bibliothek Recht: Schriftsatz-Zusammenfassung, Vertragsanalyse, Recherche-Assistent
- UI-Disclaimer: "KI-Inhalte sind keine Rechtsberatung" (rechtlich notwendig)
- Onboarding-Wizard für neue Instanzen

### M2 — Steuerberatung & Datenschutz
*Ziel: Zwei weitere Vertikals erschlossen, Markterweiterung*

**Steuerberatung:**
- Dokumenten-Workspaces pro Mandant / Geschäftsjahr
- Prompt-Bibliothek Steuern: Jahresabschluss-Analyse, BMF-Schreiben-Recherche, Belege-Kategorisierung
- DATEV-kompatibler Dokumenten-Export (Recherche erforderlich)

**Datenschutz:**
- DSGVO-Dokumentengenerator: Datenschutzerklärungen, TOMs, VVT
- Prompt-Bibliothek Datenschutz: DSFA, Auskunftsersuchen, Löschanfragen
- Vorlagen-Bibliothek für Standard-DSGVO-Dokumente

### M3 — White-Label & On-Premise
*Ziel: Enterprise-Kunden, größere Kanzleien, eigene Branding-Anforderungen*

- Custom Branding pro Instanz (Logo, Primärfarbe, Name)
- On-Premise Deployment Package (Docker Compose + Dokumentation)
- Customer Provisioning Dashboard für Dreamware-Team
- SLA-Dokumentation und Support-Struktur

---

## 4. Branchenspezifische Features im Detail

### Alle Vertikals (Cross-cutting)
- UI in Deutsch und Englisch (DE als Default)
- Custom Branding (Logo, Farben) pro Kundeninstanz
- Onboarding-Wizard beim ersten Login
- Audit-Log-Export

### Anwaltskanzlei
| Feature | Beschreibung |
|---------|-------------|
| Mandat-Workspaces | Jedes Mandat = isolierter Workspace, Dokumente nie gemischt |
| Rollenmodell | Partner (Admin), Anwalt (Standard), Sekretariat (eingeschränkt) |
| Prompt-Bibliothek | Schriftsatz-Zusammenfassung, Vertragsanalyse, Rechtsprechungs-Recherche |
| Legal Disclaimer | Pflicht-Hinweis: KI-Ausgaben sind keine Rechtsberatung |

### Steuerberatung
| Feature | Beschreibung |
|---------|-------------|
| Mandant/Jahr-Workspaces | Isolation pro Mandant und Geschäftsjahr |
| Prompt-Bibliothek | Jahresabschluss, BMF-Schreiben, Belegkategorisierung |
| DATEV-Export | Dokumente in DATEV-kompatiblem Format (Phase 2, Recherche nötig) |

### Datenschutzfirmen
| Feature | Beschreibung |
|---------|-------------|
| Dokumentengenerator | Datenschutzerklärungen, TOMs, VVT automatisch generieren |
| Prompt-Bibliothek | DSFA, Auskunftsersuchen, Löschanfragen beantworten |
| Vorlagen-Bibliothek | Standard-DSGVO-Dokumente als editierbare Templates |

---

## 5. Out of Scope (bewusste Entscheidungen)

- **Multi-Tenant Architektur** — bewusst ausgeschlossen, Single-Tenant für Berufsgeheimnis
- **US-AI-Provider als Default** — nur als explizit opt-in mit Warnung
- **Mobile App** — nicht im Scope dieser Roadmap
- **DATEV-API-Integration** — nur Dokumenten-Export, keine Live-Verbindung (Phase 2+)
- **Automatisches Provisioning** — erst M3, manuell ist für Phase 1 ausreichend
