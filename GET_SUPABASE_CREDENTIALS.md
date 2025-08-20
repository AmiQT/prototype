# 🔑 How to Get Your Supabase Credentials

## Step 1: Access Your Supabase Dashboard
1. Go to [https://supabase.com](https://supabase.com)
2. Sign in to your account
3. Select your project (or create a new one if needed)

## Step 2: Get Your Project URL and API Key
1. In your project dashboard, click on **Settings** (gear icon) in the left sidebar
2. Click on **API** in the settings menu
3. You'll see two important values:

### Project URL:
```
https://your-project-id.supabase.co
```
- This is your `supabaseUrl`
- Copy the entire URL

### API Keys:
You'll see several keys, but you need the **anon public** key:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
- This is your `supabaseAnonKey`
- Copy the entire key (it's quite long)

## Step 3: Update Your Config File

Once you have both values, I'll help you update the config file with your actual credentials.

---

**Please share your:**
1. **Project URL** (e.g., `https://abc123.supabase.co`)
2. **Anon public key** (the long JWT token)

Then I'll update the configuration file for you! 🚀

## 🔒 Security Note:
The anon public key is safe to use in your mobile app - it's designed for client-side use and has limited permissions based on your Row Level Security policies.