# 🚀 Hybrid Deployment Plan: Private AI (Gemma 3) on AWS

**Tarikh:** 14 Januari 2026  
**Status:** ✅ CODE READY - Awaiting Greenlight  
**Implementation Status:** Backend prepared with LLM abstraction layer  
**Bajet:** AWS Credits (High Priority: Performance & Stability)  
**Tujuan:** Deployment sistem AI Chatbot yang "Robust" untuk demo, bebas dari Rate Limit API awam, menggunakan 2 instance berasingan.

---

## ⚙️ Backend Code Status: READY ✅

### ✅ Completed Preparations:

1. **LLM Provider Factory** (`app/ai_assistant/llm_factory.py`)
   - ✅ Abstraction layer untuk swap Gemini ↔ Ollama
   - ✅ Environment-based configuration
   - ✅ Validation & error handling
   - ✅ Support untuk timeout dan custom settings

2. **LangChain Agent Updated** (`app/ai_assistant/langchain_agent/agent.py`)
   - ✅ Removed hardcoded Gemini dependency
   - ✅ Now uses LLM Factory
   - ✅ Backward compatible dengan existing code

3. **RAG Chain Updated** (`app/ai_assistant/rag_chain.py`)
   - ✅ Updated untuk support Ollama
   - ✅ LLM generation guna factory pattern

4. **Dependencies Updated** (`requirements.txt`)
   - ✅ Added `langchain-ollama>=0.2.0`
   - ✅ All LangChain packages up-to-date

5. **Environment Configuration** (`.env.example`)
   - ✅ Clear documentation untuk Gemini vs Ollama setup
   - ✅ Default config untuk Ollama deployment

---

## 1. Architecture Overview 🏗️

Kita menggunakan pendekatan **Microservices** dengan 2 server berasingan dalam satu AWS Region (Private Network).

*   **Machine 1 (The Body):** `t3.small` (2GB RAM)
    *   **Role:** Backend Server (FastAPI + Docker).
    *   **Tugas:** Handle user request, process logic, RAG retrieval.
    *   **Setup:** Sedia ada (Existing). Tidak perlu rebuild pipeline.
*   **Machine 2 (The Brain):** `m7i-flex.large` (8GB RAM)
    *   **Role:** Private AI Inference Server.
    *   **Tugas:** Run **Ollama** dengan model **Gemma 3 4B** (Multimodal Native).
    *   **Setup:** New Instance. Fresh setup.

---

## 2. Hardware Specification 🖥️

| Server | Instance Type | vCPU | RAM | Cost/Hour (Linux) | Role |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Backend** | `t3.small` | 2 | 2 GB | ~$0.0264 | Application Logic |
| **AI Brain** | `m7i-flex.large` | 2 | 8 GB | ~$0.1197 | Gemma 3 4B Host |

**Total Estimated Cost (24 Jam):** ~$3.50 USD (Sangat rendah berbanding bajet $90).

---

## 3. Deployment Steps: Machine 2 (The Brain) 🧠

**Arahan untuk Developer:** Sila setup instance baru ini sebagai "AI Server" sahaja.

1.  **Launch Instance:**
    *   OS: **Ubuntu 24.04 LTS** (Recommended for latest drivers).
    *   Storage: **30GB gp3** (Minimum space untuk model LLM).
    *   **Security Group:** Allow Custom TCP Port `11434` (Inbound) dari **Private IP** Machine 1 sahaja (atau `0.0.0.0/0` untuk testing sementara).

2.  **Install Ollama:**
    ```bash
    curl -fsSL https://ollama.com/install.sh | sh
    ```

3.  **Configure Network Access:**
    *   Secara default, Ollama hanya listen `localhost`. Kita perlu buka ke network.
    *   Edit service config:
        ```bash
        sudo systemctl edit ollama.service
        ```
    *   Tambah baris berikut di bawah `[Service]`:
        ```ini
        [Service]
        Environment="OLLAMA_HOST=0.0.0.0"
        ```
    *   Reload & Restart:
        ```bash
        sudo systemctl daemon-reload && sudo systemctl restart ollama
        ```

4.  **Pull Model (Gemma 3 4B):**
    *   Run command ini untuk download model Google terbaru:
    *   *Nota: Jika Gemma 3 belum available di registry standard Ollama, gunakan Gemma 2 9B atau Llama 3.1 8B sebagai alternatif.*
    ```bash
    ollama run gemma2:9b
    # ATAU jika Gemma 3 available (Check library):
    # ollama run gemma3:4b
    ```

---

## 4. Integration Steps: Machine 1 (The Body) 🔗

**Arahan untuk Developer:** Update connection string backend untuk point ke Machine 2.

1.  **Dapatkan Private IP Machine 2:**
    *   Check AWS Console. Contoh: `172.31.45.67`.
2.  **Update `.env` Backend:**
    *   Jangan hardcode dalam code. Gunakan environment variables.
    ```env
    # AI Provider Configuration
    AI_PROVIDER=ollama
    AI_BASE_URL=http://172.31.45.67:11434
    AI_MODEL_NAME=gemma2:9b
    ```
3.  **Restart Backend:**
    *   `docker restart backend_container`

---

## 5. Technical Reference: Google Gemma 3 📚

Model **Gemma 3** adalah siri model terbaru dari Google yang bersifat **Multimodal Native** (Vision-Language). Ia dioptimumkan untuk performance tinggi pada hardware terhad.

*   **Capabilities:** Teks & Imej (Multimodal).
*   **Architecture:** Sliding Window Attention (Efficient Memory).
*   **Reference Blog:** [Hugging Face Blog: Gemma 3](https://huggingface.co/blog/gemma3?utm_source=deepmind.google&utm_medium=referral&utm_campaign=gdm&utm_content=)
*   **Note:** Blog ini mengandungi perincian teknikal tentang saiz model (1B, 4B, 12B, 27B) dan keperluan RAM.

### Why Gemma 3 4B?
Dengan RAM 8GB pada instance `m7i-flex.large`:
*   Model **1B** (~815MB) terlalu kecil, membazir potensi hardware.
*   Model **4B** (~3.3GB) adalah **Sweet Spot**. Muat selesa dalam 8GB RAM dengan baki secukupnya untuk OS dan context cache.

---
*Disediakan oleh Gemini CLI Agent*

---

## 📋 EXECUTION CHECKLIST

### Phase 1: Infrastructure Setup (AWS) 🖥️

- [ ] **Step 1.1:** Launch EC2 Instance (Machine 2 - AI Server)
  - Instance Type: `m7i-flex.large` (2 vCPU, 8GB RAM)
  - OS: Ubuntu 24.04 LTS
  - Storage: 30GB gp3
  - Region: Same as Machine 1 (for private network)
  
- [ ] **Step 1.2:** Configure Security Group
  - Inbound: Custom TCP Port `11434` from Machine 1 Private IP
  - Outbound: All traffic (for downloading models)

- [ ] **Step 1.3:** Note down Machine 2 Private IP
  - Example: `172.31.45.67`
  - Will be used in backend `.env` config

### Phase 2: AI Server Setup (Machine 2) 🧠

- [ ] **Step 2.1:** SSH into Machine 2
  ```bash
  ssh -i your-key.pem ubuntu@<Machine2-Public-IP>
  ```

- [ ] **Step 2.2:** Install Ollama
  ```bash
  curl -fsSL https://ollama.com/install.sh | sh
  ```

- [ ] **Step 2.3:** Configure Network Access
  ```bash
  sudo systemctl edit ollama.service
  # Add: Environment="OLLAMA_HOST=0.0.0.0"
  sudo systemctl daemon-reload
  sudo systemctl restart ollama
  ```

- [ ] **Step 2.4:** Pull Model (Recommended: Gemma 3 4B)
  ```bash
  # Check available models first
  ollama list
  
  # Pull model (choose ONE)
  ollama pull gemma3:4b      # Best fit for 8GB RAM
  # OR
  ollama pull llama3.1:8b    # Alternative
  ```

- [ ] **Step 2.5:** Warm up model (prevent cold start)
  ```bash
  ollama run gemma3:4b "hello" --keepalive 24h
  ```

- [ ] **Step 2.6:** Verify Ollama is accessible
  ```bash
  curl http://localhost:11434/api/tags
  # Should return JSON with available models
  ```

### Phase 3: Backend Configuration (Machine 1) 🔗

- [ ] **Step 3.1:** Update `.env` on Machine 1
  ```bash
  # SSH into Machine 1
  cd ~/app
  nano .env
  
  # Update these variables:
  AI_PROVIDER=ollama
  AI_BASE_URL=http://<Machine2-Private-IP>:11434
  AI_MODEL_NAME=gemma3:4b
  AI_TEMPERATURE=0.7
  AI_TIMEOUT=30
  ```

- [ ] **Step 3.2:** Rebuild Docker image (CI/CD will do this automatically)
  ```bash
  # If manual deployment needed:
  docker pull ghcr.io/amiqt/prototype-backend:latest
  docker stop talent-api
  docker rm talent-api
  docker run -d --name talent-api --restart unless-stopped \
    -p 8000:8000 --env-file ~/app/.env \
    ghcr.io/amiqt/prototype-backend:latest
  ```

- [ ] **Step 3.3:** OR simply push to GitHub (CI/CD will handle)
  ```bash
  git add .env
  git commit -m "feat: switch to Ollama provider"
  git push origin main
  # Wait ~3-5 minutes for CI/CD to complete
  ```

### Phase 4: Testing & Verification ✅

- [ ] **Step 4.1:** Test Ollama connectivity from Machine 1
  ```bash
  # SSH into Machine 1
  curl http://<Machine2-Private-IP>:11434/api/tags
  # Should return JSON with models
  ```

- [ ] **Step 4.2:** Check backend health
  ```bash
  curl http://localhost:8000/health
  # Should return {"status": "healthy"}
  ```

- [ ] **Step 4.3:** Test AI endpoint with simple query
  ```bash
  curl -X POST http://localhost:8000/api/ai/v3/command \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer YOUR_TOKEN" \
    -d '{"command": "Hai, apa khabar?"}'
  ```

- [ ] **Step 4.4:** Verify response time and quality
  - First request: ~10-30s (model loading)
  - Subsequent requests: <3s
  - Check response makes sense

- [ ] **Step 4.5:** Monitor logs for errors
  ```bash
  # Machine 2 (Ollama logs)
  sudo journalctl -u ollama -f
  
  # Machine 1 (Backend logs)
  docker logs -f talent-api
  ```

### Phase 5: Optimization (Optional) 🚀

- [ ] **Step 5.1:** Enable systemd auto-start for Ollama
  ```bash
  sudo systemctl enable ollama
  ```

- [ ] **Step 5.2:** Setup monitoring (CloudWatch)
  - Monitor CPU/RAM usage on Machine 2
  - Alert if usage > 90%

- [ ] **Step 5.3:** Test failover (if using fallback)
  - Stop Ollama temporarily
  - Verify backend falls back to Gemini (if configured)

---

## 🎯 Success Criteria

✅ Ollama responding on port 11434  
✅ Backend successfully connects to Ollama  
✅ AI responses generated correctly  
✅ Response time <3s (after warm-up)  
✅ No rate limit errors  
✅ CI/CD pipeline not affected  
✅ Tunnel still running (screen session)  

---

## 🆘 Troubleshooting Guide

### Issue: "Connection refused" from Machine 1
**Solution:** Check Security Group allows port 11434 from Machine 1 Private IP

### Issue: Slow first response (>30s)
**Solution:** Normal for cold start. Run warm-up command:
```bash
ollama run gemma3:4b "test" --keepalive 24h
```

### Issue: Out of memory on Machine 2
**Solution:** 
1. Check model size with `ollama list`
2. Switch to smaller model: `ollama pull gemma2:2b`
3. Update `.env` with new model name

### Issue: CI/CD deployment fails
**Solution:** Check if `langchain-ollama` installed:
```bash
pip list | grep langchain-ollama
```

---

## 📊 Expected Outcomes

| Metric | Before (Gemini) | After (Ollama) | Improvement |
|--------|----------------|----------------|-------------|
| **Cost per 1000 requests** | $0.50 | $0.00 | 100% savings |
| **Rate Limit** | 60 RPM | Unlimited | ♾️ |
| **Response Time** | 2-5s | 1-3s | 40% faster |
| **Availability** | 99.9% (Google) | 99.5% (EC2) | Similar |
| **Control** | None | Full | ✅ |

---

*Disediakan oleh Gemini CLI Agent*
