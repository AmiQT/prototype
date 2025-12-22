# 🤖 AI Agentic Dashboard Master Reference

**Tarikh**: 19 September 2025  
**Status**: Pelan menyeluruh bersedia untuk implementasi  
**Bajet**: RM0 (guna OpenRouter free-tier + pseudo-AI)

---

## 1. Ringkasan Strategik

- **Objektif**: Transform web dashboard admin kepada pengalaman agentic AI yang boleh automasi kerja rutin, beri insight dan sokong keputusan.
- **Pendekatan fasa**:
  1. **Pseudo-AI & Template Automation** – pengalaman ala AI tanpa kos.
  2. **OpenRouter Free-Tier PoC** – demo real AI guna model percuma.
  3. **Model Premium (Opsyen Masa Depan)** – hanya bila ada dana/bukti ROI.
- **Platform sedia ada**: Supabase (Auth/DB), FastAPI backend, Cloudinary untuk media, web dashboard vanilla JS.

---

## 2. Gambaran Seni Bina

```
┌─────────────────────────┐
│  Web Dashboard (JS)     │
│  + AI Assistant UI Box  │
└────────────┬────────────┘
             │ (SSE/WebSocket)
┌────────────▼────────────┐
│  AI Orchestrator Layer  │  ← FastAPI service / worker
│  • Natural Language      │
│  • Command Parser        │
│  • Action Executor       │
│  • Model Router          │
└────────────┬────────────┘
             │
┌────────────▼────────────┐
│ Existing FastAPI API    │
└────────────┬────────────┘
             │
┌────────────▼────────────┐
│ Supabase PostgreSQL     │
└─────────────────────────┘
```

Tambahan opsyen: Redis queue/cache untuk tugas panjang & throttling, logging/monitoring (Sentry, Prometheus).

---

## 3. Fitur AI Mengikut Fasa

### Fasa 1 – Pseudo-AI (RM0)
- Command parser ringkas (regex / pattern) untuk `create users`, `generate report`, `search`.
- Template data generator (nama pelajar Malaysia, email, laporan).
- Rule-based analytics (contoh: kira mood kampus guna metrik asas).
- UI: chat box + log tindakan + confirm dialog.

### Fasa 2 – PoC OpenRouter Free Tier
- Model utama: **DeepSeek V3.1 (80%)**, **Qwen 3 (15%)**, **Gemini 2.5 Pro Experimental (5%)**.
- Hard limit: **50 request/hari** → guna caching & fallback pseudo-AI.
- Use case demo:
  - Batch user creation dengan nama realistik.
  - Analitik student at-risk + cadangan intervensi.
  - Email/pengumuman multi-bahasa.
  - Kandungan pemasaran/pelaporan automatik.

### Fasa 3 – Advanced (Bila ada bajet)
- Predictive analytics mendalam (DeepSeek/Gemini berbayar).
- Moderation, workflow automation kompleks.
- Integrasi LMS/SIS, voice interface, model self-host (Qwen local).

---

## 4. Pengalaman Admin (AI Assistant)

- **UI Komponen**: teks input, butang send, log reasoning, streaming hasil, butang aksi lanjut (Export, Email, Undo).
- **Contoh command**:
  - “Buat 20 student Computer Science intake 2025.”
  - “Cari pelajar yang engagement tinggi tapi achievement rendah.”
  - “Generate laporan prestasi semester & email kepada semua HOD.”
  - “Terjemah mesej sambutan untuk pelajar antarabangsa mengikut bahasa mereka.”
- **Flow**: Input → Validasi permission → Proses (pseudo atau model AI) → Tindakan backend → Papar hasil + opsyen susulan.

---

## 5. Keperluan Sistem & Guardrail

- **Permission Matrix** (`admin`, `manager`, `viewer`) kawal command sensitif.
- **Validasi**: Batch size limit, confirm prompt sebelum tindakan kritikal.
- **Logging**: Simpan setiap command + respon + tindakan (audit, debug).
- **Fallback**: Bila quota habis atau AI gagal → guna template/rule-based result.
- **Security**: JWT Supabase, rate limiting, sanitasi input, moderation asas.

---

## 6. Plan Implementasi 6 Minggu (Free-Tier Mode)

| Minggu | Fokus | Deliverable |
| --- | --- | --- |
| 1 | Setup OpenRouter client, struktur orchestrator, fallback pseudo-AI | Command asas berfungsi (create/search) |
| 2 | Integrasi user mgmt AI, batch operation, error handling | Demo batch create + report ringkas |
| 3 | Analytics & insight (DeepSeek), multilingual support (Qwen) | Laporan at-risk + mesej multi-bahasa |
| 4 | Creative content (Gemini), streaming UI, caching | Poster/email template automatik |
| 5 | Polishing, guardrail, logging, dokumentasi | UX mantap + log audit |
| 6 | Ujian penuh, training admin, track quota harian | Demo stakeholder & plan fasa seterusnya |

---

## 7. Infrastruktur Tambahan (Opsyenal)

- **Redis**: queue untuk long-running task & caching respon AI.
- **Supabase Functions / Edge**: scheduled job, webhooks.
- **Monitoring**: Prometheus + Grafana, Sentry, Supabase logs.
- **Testing**: Pytest (backend), Vitest (JS), integration test command utama.

---

## 8. Kos & ROI (RM0 fasa semasa)

- **Kos API**: RM0 selagi ≤50 request/hari (free tier).
- **Kos Infra**: ikut sedia ada (Render, Supabase free tier, Cloudinary free tier).
- **Penjimatan Masa** (anggaran semasa PoC):
  - Automasi admin: jimat ±20 jam/minggu.
  - Laporan: jimat ±10 jam/minggu.
  - Komunikasi: jimat ±5 jam/minggu.
  - Nilai masa (RM25/jam): ±RM3,750/bulan.
- **ROI**: Infinite sepanjang kekal free tier (kos RM0, manfaat >RM100k/tahun).

---

## 9. Checklist Kejayaan

- [ ] AI assistant UI tersedia di dashboard.
- [ ] ≥10 command utama berfungsi dengan pseudo-AI fallback.
- [ ] Integrasi OpenRouter → DeepSeek/Qwen/Gemini free-tier stabil.
- [ ] Logging & guardrail aktif (permission, confirm, audit).
- [ ] Limit quota dipatuhi (≤50/hari) + fallback jelas.
- [ ] Admin training & dokumentasi siap.
- [ ] Nilai masa/jimat kerja direkod untuk pitch funding seterusnya.

---

## 10. Rujukan Cepat Model OpenRouter (Free Tier)

| Model | Kegunaan Utama | Catatan |
| --- | --- | --- |
| DeepSeek V3.1 | Analitik, reasoning kompleks | Laju, free, bagus untuk SQL/predictive |
| Qwen 3 | Multilingual, conversation | 119 bahasa, cultural adapt, free |
| Gemini 2.5 Pro Experimental | Kandungan kreatif | Experimental, masih free tapi mungkin rate limit ketat |

Cara guna: `model=deepseek-chat`, `model=qwen-plus`, `model=gemini-2.5-pro-exp` (ikut alias OpenRouter terkini). Pastikan log pemakaian untuk monitor quota.

---

## 11. Next Step Selepas PoC Berjaya

1. Bentang hasil (masa jimat, demo live) kepada pihak pentadbiran.
2. Cadang bajet untuk naik taraf (API berbayar, infra worker, moderation lanjutan).
3. Rancang integrasi dengan sistem universiti lain (SIS, LMS, email rasmi).
4. Bina modul AI tambahan: content moderation, workflow automation, student success coach.

---

> **Nota**: Dokumen ni gabungkan point penting semua fail (`ai-agentic-features-proposal`, `ai-admin-usage-guide`, `ai-features-practical-examples`, `ai-zero-budget-reality-check`, `openrouter-development-phase`, `real-ai-implementation-plan`, `architecture`, `performance`, `debugging`). Rujuk fail asal kalau perlu detail mendalam.


