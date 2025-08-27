# Cloudinary Setup Guide untuk Flutter App - UPDATED ✅

## 🔍 **Masalah yang Ditemui & Diperbaiki:**

### 1. **Storage Bucket Error** ❌ → ✅ **FIXED**
```
Error uploading file to storage: StorageException(message: Bucket not found, statusCode: 404, error: Bucket not found)
```
- **Penyebab**: Code cuba guna Supabase Storage, tapi anda pakai Cloudinary
- **Penyelesaian**: ✅ Updated ShowcaseService untuk guna Cloudinary

### 2. **Feed Tidak Auto Refresh** ❌ → ✅ **FIXED**
- **Penyebab**: Real-time subscription tidak berfungsi dengan betul
- **Penyelesaian**: ✅ Enhanced real-time stream methods

### 3. **Inconsistent Storage Logic** ❌ → ✅ **FIXED**
- **Penyebab**: Upload guna Cloudinary, tapi delete guna Supabase Storage
- **Penyelesaian**: ✅ Updated semua methods untuk guna Cloudinary consistently

## 🛠️ **Penyelesaian Lengkap: Setup Cloudinary untuk Media Upload**

### **Step 1: Setup Cloudinary Account**

1. **Buka [Cloudinary Dashboard](https://cloudinary.com/console)**
2. **Sign up/Login** ke account anda
3. **Copy credentials** dari Dashboard:
   - Cloud Name
   - API Key
   - API Secret

### **Step 2: Setup Upload Preset (Untuk Unsigned Uploads)**

1. **Dashboard → Settings → Upload**
2. **Scroll ke "Upload presets"**
3. **Click "Add upload preset"**
4. **Set:**
   - **Preset name**: `showcase_media_preset` (atau nama yang anda suka)
   - **Signing Mode**: `Unsigned`
   - **Folder**: `showcase_media`
5. **Save preset**

### **Step 3: Update Flutter App Configuration - CRITICAL!**

1. **Update `mobile_app/lib/config/cloudinary_config.dart`:**
   ```dart
   class CloudinaryConfig {
     // REPLACE dengan credentials sebenar anda!
     static const String _cloudName = 'your_actual_cloud_name';
     static const String _apiKey = 'your_actual_api_key';
     static const String _apiSecret = 'your_actual_api_secret';
     static const String _uploadPreset = 'showcase_media_preset'; // Nama preset anda
   }
   ```

2. **Restart Flutter app**

### **Step 4: Test Media Upload**

1. **Create post dengan gambar**
2. **Check logs** untuk upload progress
3. **Verify** gambar muncul di Cloudinary Dashboard

## 📱 **Cara Guna di UI:**

### **1. PostCreation Screen:**
```dart
// Selepas post berjaya dibuat:
await showcaseService.createShowcasePost(
  content: 'My post content',
  mediaFiles: [selectedImageFile], // File object
  category: PostCategory.general,
  privacy: PostPrivacy.public,
);

// Trigger refresh:
await showcaseService.refreshFeed();
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

### **1. Test Cloudinary Setup:**
- Upload gambar kecil (< 5MB)
- Check Cloudinary Dashboard → Media Library
- Verify file wujud dalam folder `showcase_media`

### **2. Test Auto-Refresh:**
- Create post dengan gambar
- Check feed update secara automatik
- Verify real-time subscription berfungsi

### **3. Test Error Handling:**
- Upload file terlalu besar
- Upload file type yang tidak support
- Check error messages

### **4. Test Delete Functionality:**
- Delete post dengan gambar
- Verify gambar dihapus dari Cloudinary
- Check feed update

## 🔧 **Troubleshooting:**

### **Jika Upload Masih Error:**
1. ✅ Check Cloudinary credentials sudah betul
2. ✅ Verify upload preset configuration
3. ✅ Check internet connection
4. ✅ Verify file size limits

### **Jika Feed Masih Tidak Refresh:**
1. ✅ Restart app
2. ✅ Check real-time subscription
3. ✅ Verify database triggers

### **Jika Upload Lambat:**
1. ✅ Compress images sebelum upload
2. ✅ Check internet connection
3. ✅ Use smaller file sizes

## 📋 **Cloudinary Configuration Checklist:**

- [ ] Cloudinary account created
- [ ] Cloud Name copied
- [ ] API Key copied  
- [ ] API Secret copied
- [ ] Upload preset created (unsigned)
- [ ] Flutter config updated dengan credentials betul
- [ ] App restarted
- [ ] Test upload successful
- [ ] Test delete successful
- [ ] Test auto-refresh berfungsi

## ✅ **Expected Results Setelah Fix:**

- **Media upload berfungsi** ke Cloudinary ✅
- **Feed auto-refresh** selepas post creation ✅
- **Real-time updates** berfungsi ✅
- **No more storage bucket errors** ✅
- **Delete functionality** berfungsi dengan Cloudinary ✅
- **Consistent storage logic** ✅

## 🚨 **CRITICAL NOTES:**

### **1. Credentials MESTI Diupdate:**
```dart
// ❌ JANGAN guna placeholder values!
static const String _cloudName = 'your_actual_cloud_name';
static const String _apiKey = 'your_actual_api_key';
static const String _apiSecret = 'your_actual_api_secret';
static const String _uploadPreset = 'your_actual_upload_preset';

// ✅ Guna credentials sebenar!
static const String _cloudName = 'mycloud123';
static const String _apiKey = '123456789012345';
static const String _apiSecret = 'abcdefghijklmnop';
static const String _uploadPreset = 'showcase_media_preset';
```

### **2. Upload Preset MESTI Unsigned:**
- Signing Mode: `Unsigned`
- Folder: `showcase_media`
- Public: `Yes`

## 📞 **Support:**

Jika masih ada masalah:
1. Check Flutter logs
2. Verify Cloudinary setup
3. Check upload preset configuration
4. Test dengan file yang lebih kecil
5. Restart app dan test lagi
6. Verify credentials sudah betul

---

**Nota:** Pastikan semua Cloudinary credentials betul dan upload preset sudah disetup dengan betul. Unsigned uploads adalah cara yang paling mudah untuk Flutter apps.
