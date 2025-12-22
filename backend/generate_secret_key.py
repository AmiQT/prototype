"""
Generate a secure SECRET_KEY for Railway deployment
Run this: python generate_secret_key.py
"""
import secrets
import logging

# Configure logging for CLI script
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

logger.info("=" * 60)
logger.info("🔐 GENERATING SECRET KEY FOR RAILWAY")
logger.info("=" * 60)
logger.info("\nYour new SECRET_KEY:")
logger.info("-" * 60)
secret_key = secrets.token_urlsafe(32)
logger.info(secret_key)
logger.info("-" * 60)
logger.info("\n✅ Copy this value to Railway Variables → SECRET_KEY")
logger.info("\n⚠️  IMPORTANT: Keep this secret! Never commit to Git!")
logger.info("=" * 60)
