"""
Generate a secure SECRET_KEY for Railway deployment
Run this: python generate_secret_key.py
"""
import secrets

print("=" * 60)
print("🔐 GENERATING SECRET KEY FOR RAILWAY")
print("=" * 60)
print("\nYour new SECRET_KEY:")
print("-" * 60)
secret_key = secrets.token_urlsafe(32)
print(secret_key)
print("-" * 60)
print("\n✅ Copy this value to Railway Variables → SECRET_KEY")
print("\n⚠️  IMPORTANT: Keep this secret! Never commit to Git!")
print("=" * 60)
