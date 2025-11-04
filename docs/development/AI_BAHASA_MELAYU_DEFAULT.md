# AI Chatbot - Bahasa Melayu sebagai Bahasa Default

## 📋 Ringkasan

AI chatbot dalam sistem UTHM kini menggunakan **Bahasa Melayu sebagai bahasa default** untuk semua respons. Ini penting untuk NLP (Natural Language Processing) yang ditujukan kepada pengguna Malaysia.

## 🎯 Objektif

- Menyediakan pengalaman pengguna yang lebih natural untuk pengguna Malaysia
- Meningkatkan pemahaman konteks budaya dan bahasa tempatan
- Memastikan respons AI lebih sesuai dengan cara berkomunikasi pengguna Malaysia
- Menyokong code-switching (campuran BM-English) yang natural

## ✅ Perubahan Yang Dibuat

### 1. System Prompt (manager.py)

**Lokasi**: `backend/app/ai_assistant/manager.py`

**Perubahan Utama**:
```python
# Sebelum:
"You are an agentic AI assistant for the UTHM dashboard system."

# Sekarang:
"Anda adalah pembantu AI agentic untuk sistem papan pemuka UTHM."
```

**Arahan Default**:
- SENTIASA RESPONS DALAM BAHASA MELAYU sebagai default
- Boleh faham dan respons dalam Bahasa Melayu dan English
- Code-switching adalah normal dan digalakkan
- Padan dengan nada, gaya, dan tenaga pengguna

### 2. Contoh Penggunaan (Examples)

Semua contoh dalam system prompt kini menggunakan format:
```
Pengguna: "Pilih 1 student random" 
→ Respons: "Okay, saya dah pilih 1 pelajar secara rawak..."

Pengguna: "Berapa student dalam sistem?" 
→ Respons: "Ada [X] pelajar dalam sistem..."
```

### 3. Clarification System

**Lokasi**: `backend/app/ai_assistant/clarification_system.py`

**Template Clarification dalam Bahasa Melayu**:
```python
'missing_department': {
    'question': "Awak tanya pasal pelajar, tapi tak specify jabatan. Awak nak tengok pelajar dari semua jabatan atau jabatan tertentu?",
    'suggestion': "Cuba tambah jabatan macam 'Sains Komputer' atau 'FSKTM' dalam query awak."
}
```

### 4. Response Templates

**Lokasi**: 
- `backend/app/ai_assistant/response_variation.py`
- `backend/app/ai_assistant/template_manager.py`

**Template Respons dalam Bahasa Melayu**:
```python
# Greeting
"Hai! Apa khabar? {user_name}, saya AI assistant UTHM sedia nak tolong."
"Wah bestnya jumpa awak! 😊 Saya AI assistant UTHM, ready to help."

# Query Results
"Wah bestnya! 🎉 Saya jumpa **{result_count} students** mengikut permintaan awak!"
"Jumpa lah! Saya dapatkan {result_count} students untuk awak. Best kan?"

# Confirmation
"Wah bestnya! Saya dah proses permintaan awak. Sure lah! Saya dah faham."
"Tqvm! Dah done proses tadi. Everything is set and ready for awak."
```

## 🔧 Cara Sistem Berfungsi

### 1. Language Detection & Response

AI akan:
1. Detect bahasa yang pengguna guna dalam query
2. Respond dalam **Bahasa Melayu secara default**
3. Boleh switch ke English jika pengguna terang-terang guna full English
4. Support code-switching (campuran BM-English)

### 2. Context Understanding

AI faham konteks bahasa Malaysia:
- "sekalai lagi" = repeat last action
- "tadi" = previous/earlier
- "sebelum" = before
- Natural expressions: "wah bestnya", "okay lah", "sure lah"

### 3. Tools & Functions

Semua tools tetap sama (query_students, query_events, dll.) tapi:
- Tool calls dalam English (technical)
- Respons kepada pengguna dalam Bahasa Melayu
- Penjelasan hasil dalam Bahasa Melayu

## 📝 Contoh Penggunaan

### Contoh 1: Query Pelajar
```
User: "Tunjuk pelajar FSKTM"
AI: "Baiklah, ini pelajar dari FSKTM..."
[Calls: query_students(department="FSKTM")]
AI: "Saya jumpa 50 pelajar dari FSKTM. Ini senarai mereka..."
```

### Contoh 2: Query Statistik
```
User: "Berapa student dalam sistem?"
AI: "Sebentar, saya check..."
[Calls: get_system_stats()]
AI: "Ada 250 pelajar dalam sistem sekarang. 150 lelaki dan 100 perempuan."
```

### Contoh 3: Code-Switching Natural
```
User: "Show me top 5 students dengan CGPA tinggi"
AI: "Okay! Saya cari top 5 students dengan CGPA paling tinggi..."
[Calls: query_students(sort_by="cgpa", order="desc", limit=5)]
AI: "Ni dia top 5 students dengan CGPA tertinggi:
1. Ahmad (CGPA: 3.95)
2. Siti (CGPA: 3.92)
..."
```

### Contoh 4: Clarification Request
```
User: "Nak tengok pelajar"
AI: "Awak tanya pasal pelajar, tapi tak specify jabatan. Awak nak tengok pelajar dari semua jabatan atau jabatan tertentu?"
User: "FSKTM sahaja"
AI: "Baik! Ini pelajar dari FSKTM..."
```

## 🌟 Features Bahasa Melayu

### 1. Natural Expressions
- ✅ "Wah bestnya!"
- ✅ "Okay lah!"
- ✅ "Sure lah!"
- ✅ "Tqvm!" (Thank you very much)
- ✅ Emoji yang sesuai: 😊 🎉 📅

### 2. Contextual Understanding
- ✅ "sekalai lagi" → repeat last action
- ✅ "tadi" → refer to previous
- ✅ "yang akan datang" → upcoming
- ✅ "semua" → all

### 3. Professional Yet Friendly
- Maintain profesional tone
- Mesra dan approachable
- Sesuai dengan budaya Malaysia
- Natural code-switching

## 🔄 Backward Compatibility

Sistem masih support:
- ✅ Full English queries
- ✅ Full Malay queries
- ✅ Code-switching (campuran)
- ✅ Technical terms dalam English
- ✅ Semua tools dan fungsi existing

## 🧪 Testing

### Test Cases untuk Bahasa Melayu:

1. **Basic Query BM**:
   ```
   Input: "Berapa pelajar dalam sistem?"
   Expected: Response dalam BM dengan data yang betul
   ```

2. **Code-Switching**:
   ```
   Input: "Show me students dengan CGPA tinggi"
   Expected: Response dalam BM with proper data
   ```

3. **Clarification BM**:
   ```
   Input: "Tunjuk pelajar"
   Expected: Clarification question dalam BM
   ```

4. **Repeat Action**:
   ```
   Input: "sekalai lagi"
   Expected: Repeat last tool call, respond dalam BM
   ```

## 📊 Impact

### Before (English Default):
```
User: "Berapa student ada?"
AI: "I found 250 students in the system."
[Not natural for Malaysian users]
```

### After (Malay Default):
```
User: "Berapa student ada?"
AI: "Ada 250 pelajar dalam sistem sekarang. 150 lelaki dan 100 perempuan."
[Natural and contextual]
```

## 🚀 Future Enhancements

1. **Enhanced NLP for Malay**:
   - Better entity extraction untuk BM
   - Improved intent classification untuk mixed language
   - Context-aware responses

2. **Dialect Support**:
   - Northern dialect awareness
   - Southern dialect awareness
   - Urban vs rural expressions

3. **Formal vs Informal**:
   - Auto-detect formality level
   - Adjust response tone accordingly
   - Professional mode for admin users

## 📚 References

- System Prompt: `backend/app/ai_assistant/manager.py` (lines 200-280)
- Clarification: `backend/app/ai_assistant/clarification_system.py`
- Templates: `backend/app/ai_assistant/response_variation.py`
- Template Manager: `backend/app/ai_assistant/template_manager.py`

## ✨ Kesimpulan

AI chatbot kini lebih natural dan sesuai untuk pengguna Malaysia dengan:
- ✅ Bahasa Melayu sebagai default
- ✅ Code-switching support
- ✅ Contextual understanding
- ✅ Natural expressions
- ✅ Professional yet friendly tone

Sistem ini direka untuk memberikan pengalaman yang terbaik kepada pengguna Malaysia sambil mengekalkan keupayaan teknikal yang powerful!

---

**Dikemaskini**: November 5, 2025
**Status**: ✅ Implemented dan Active
