# 🧠 Self-Hosted LLM Setup Guide

> **Setup untuk run AI model (qwen2.5:3b) secara local pada laptop dengan GPU, connected ke EC2 backend via Tailscale VPN.**

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Internet                                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    Cloudflare     ┌──────────────────────┐   │
│  │ Web Dashboard │ ───Tunnel───────> │  EC2 Backend         │   │
│  │ (Vercel)      │                   │  (FastAPI + Docker)  │   │
│  └──────────────┘                   └──────────┬───────────┘   │
│                                                 │                │
│                                      Tailscale VPN               │
│                                                 │                │
│                                      ┌──────────▼───────────┐   │
│                                      │  Laptop (Local)      │   │
│                                      │  ├─ Ollama Server    │   │
│                                      │  ├─ qwen2.5:3b Model │   │
│                                      │  └─ RTX 3050 GPU     │   │
│                                      └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Prerequisites

### Laptop Requirements
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| GPU | 4GB VRAM | 6GB+ VRAM |
| RAM | 8GB | 16GB |
| Storage | 10GB free | 20GB free |
| OS | Windows 10/11 | Windows 11 |

### Software Required
- [Ollama](https://ollama.com/download/windows)
- [Tailscale](https://tailscale.com/download)
- PowerShell (as Admin)

---

## 🚀 Setup Steps

### Step 1: Install Ollama (Laptop)

```powershell
# Download dari https://ollama.com/download/windows
# Atau via winget:
winget install Ollama.Ollama
```

### Step 2: Pull AI Model

```powershell
ollama pull qwen2.5:3b
```

**Alternative models untuk 4GB VRAM:**
| Model | Size | Speed |
|-------|------|-------|
| `qwen2.5:3b` | 2GB | ⚡ Fast |
| `gemma2:2b` | 1.5GB | ⚡⚡ Faster |
| `llama3.2:3b` | 2.5GB | ⚡ Fast |

### Step 3: Install Tailscale (Both Machines)

**Laptop:**
```powershell
winget install tailscale.tailscale
# Login dengan Google/GitHub
```

**EC2:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# Login dengan same account
```

### Step 4: Configure Windows Firewall

**PowerShell as Admin:**
```powershell
New-NetFirewallRule -DisplayName "Ollama API" -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow
```

### Step 5: Get Tailscale IPs

**Laptop:**
```powershell
tailscale ip -4
# Example output: 100.86.229.12
```

**EC2:**
```bash
tailscale ip -4
# Example output: 100.127.55.24
```

### Step 6: Update EC2 Backend .env

```bash
nano ~/app/.env
```

```env
# AI Configuration
AI_PROVIDER=ollama
AI_BASE_URL=http://100.86.229.12:11434
AI_MODEL_NAME=qwen2.5:3b
AI_TEMPERATURE=0.7
AI_TIMEOUT=30
```

### Step 7: Restart Backend Container

```bash
docker stop talent-api && docker rm talent-api
docker run -d --name talent-api --restart unless-stopped \
  -p 8000:8000 --env-file ~/app/.env \
  ghcr.io/amiqt/prototype-backend:latest
```

---

## 🎯 Starting for Demo

### Checklist Sebelum Demo:

1. **✅ Tailscale Connected (Auto on startup)**
   ```powershell
   tailscale status
   ```

2. **✅ Start Ollama dengan 0.0.0.0 binding**
   ```powershell
   # Close Ollama from system tray first
   $env:OLLAMA_HOST = "0.0.0.0"
   ollama serve
   ```
   > ⚠️ Keep terminal open!

3. **✅ Verify Connection dari EC2**
   ```bash
   curl http://100.86.229.12:11434/api/tags
   ```

4. **✅ Test Web Dashboard**
   - Open https://student-talent-profiling-app.vercel.app
   - Try AI chat

---

## 🔧 Troubleshooting

### Problem: "curl empty response"

**Solution:** Restart Ollama dengan OLLAMA_HOST
```powershell
$env:OLLAMA_HOST = "0.0.0.0"
ollama serve
```

### Problem: "Connection refused"

**Solution:** Check Tailscale status
```bash
sudo tailscale status
ping 100.86.229.12
```

### Problem: "Backend using Gemini instead of Ollama"

**Solution:** Recreate container (docker restart doesn't reload .env)
```bash
docker stop talent-api && docker rm talent-api
docker run -d --name talent-api --restart unless-stopped \
  -p 8000:8000 --env-file ~/app/.env \
  ghcr.io/amiqt/prototype-backend:latest
```

### Problem: "403 Forbidden via ngrok/Cloudflare"

**Solution:** Use Tailscale instead. Free tunnels block API requests.

---

## 📊 Performance

| Metric | Gemini API | Self-Hosted (RTX 3050) |
|--------|------------|------------------------|
| Response Time | 2-5s | 0.7-2s |
| Cost | $0.001/query | FREE |
| Token Limit | 1M/day | Unlimited |
| Privacy | External API | Local only |
| Internet Required | Yes | No (after VPN setup) |

---

## 🔒 Security Notes

1. **Tailscale VPN** - End-to-end encrypted
2. **No data leaves local network** (except through VPN tunnel)
3. **GEMINI_API_KEY** can remain for fallback/analytics

---

## 📁 Files Modified

- `backend/.env` - AI provider configuration
- `backend/app/ai_assistant/llm_factory.py` - Provider abstraction
- Windows Firewall - Port 11434 rule

---

## 🔄 Switching Back to Gemini

If needed, update `.env`:
```env
AI_PROVIDER=gemini
AI_MODEL_NAME=gemini-2.5-flash
```

Then recreate container.

---

*Last updated: 2026-01-14*
