# Supabase Media Upload & Auto-Refresh Fix Guide

## 🔍 **Masalah yang Ditemui:**

### 1. **Storage Bucket Error** ❌
```
Error uploading file to storage: StorageException(message: Bucket not found, statusCode: 404, error: Bucket not found)
```

### 2. **Feed Tidak Auto Refresh** ❌
- Post berjaya dibuat tapi feed tidak update
- Real-time subscription tidak berfungsi

## 🛠️ **Penyelesaian Lengkap:**

### **Step 1: Setup Supabase Storage**

1. **Buka Supabase Dashboard** → SQL Editor
2. **Run script ini:**
   ```sql
   -- Copy dan paste seluruh kandungan dari: backend/setup_supabase_storage.sql
   ```

3. **Verify Storage Bucket:**
   - Dashboard → Storage → Buckets
   - Pastikan `showcase-media` bucket wujud

### **Step 2: Update Flutter App**

1. **Restart Flutter app** selepas setup storage
2. **Test media upload** dengan gambar kecil (< 5MB)
3. **Check logs** untuk upload progress

### **Step 3: Fix Auto-Refresh**

**Gunakan method yang betul untuk real-time updates:**

```dart
// ❌ Jangan guna ini (tidak auto-refresh):
Stream<List<ShowcasePostModel>> getShowcasePostsStream(...)

// ✅ Guna ini (auto-refresh):
Stream<List<ShowcasePostModel>> getShowcasePostsRealtimeStream(...)
```

## 📱 **Cara Guna di UI:**

### **1. PostCreation Screen:**
```dart
// Selepas post berjaya dibuat:
await showcaseService.createShowcasePost(...);

// Trigger refresh:
await showcaseService.refreshFeed();

// Atau refresh UI secara manual:
setState(() {
  // Refresh UI state
});
```

### **2. ShowcaseFeed Screen:**
```dart
// Guna real-time stream untuk auto-refresh:
StreamBuilder<List<ShowcasePostModel>>(
  stream: showcaseService.getShowcasePostsRealtimeStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          return ModernPostCard(post: snapshot.data![index]);
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

## 🚀 **Testing Steps:**

### **1. Test Storage Setup:**
- Upload gambar kecil (< 1MB)
- Check Supabase Storage → showcase-media bucket
- Verify file wujud

### **2. Test Auto-Refresh:**
- Create post dengan gambar
- Check feed update secara automatik
- Verify real-time subscription berfungsi

### **3. Test Error Handling:**
- Upload file terlalu besar
- Upload file type yang tidak support
- Check error messages

## 🔧 **Troubleshooting:**

### **Jika Storage Masih Error:**
1. Check Supabase project settings
2. Verify RLS policies
3. Check bucket permissions

### **Jika Feed Masih Tidak Refresh:**
1. Restart app
2. Check real-time subscription
3. Verify database triggers

### **Jika Upload Lambat:**
1. Compress images sebelum upload
2. Check internet connection
3. Use smaller file sizes

## ✅ **Expected Results:**

- **Media upload berfungsi** tanpa error
- **Feed auto-refresh** selepas post creation
- **Real-time updates** berfungsi
- **No more crashes** dari image loading

## 📞 **Support:**

Jika masih ada masalah:
1. Check Flutter logs
2. Verify Supabase setup
3. Test dengan file yang lebih kecil
4. Restart app dan test lagi

---

**Nota:** Pastikan semua steps diikuti dengan betul. Storage setup adalah critical untuk media upload berfungsi.
