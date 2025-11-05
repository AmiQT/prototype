"""
Cache Manager

In-memory caching system for ML predictions with TTL (time-to-live) support.
Helps respect Gemini API rate limits by caching results.
"""

from datetime import datetime, timedelta
from typing import Any, Dict, Optional
import logging

logger = logging.getLogger(__name__)


class CacheEntry:
    """Single cache entry with TTL"""

    def __init__(self, value: Any, ttl: timedelta):
        self.value = value
        self.created_at = datetime.now()
        self.ttl = ttl

    def is_expired(self) -> bool:
        """Check if entry has expired"""
        return datetime.now() > (self.created_at + self.ttl)

    def __repr__(self) -> str:
        age_seconds = (datetime.now() - self.created_at).total_seconds()
        ttl_seconds = self.ttl.total_seconds()
        return f"<CacheEntry age={age_seconds:.0f}s ttl={ttl_seconds:.0f}s>"


class CacheManager:
    """
    In-memory cache with TTL management

    Usage:
        cache = CacheManager(max_size=1000, default_ttl=timedelta(hours=24))
        cache.set("student_123", {"risk": 0.45}, ttl=timedelta(hours=12))
        result = cache.get("student_123")
        cache.invalidate("student_123")
    """

    def __init__(self, max_size: int = 1000, default_ttl: timedelta = None):
        self.max_size = max_size
        self.default_ttl = default_ttl or timedelta(hours=24)
        self._cache: Dict[str, CacheEntry] = {}
        self.hits = 0
        self.misses = 0

    def set(self, key: str, value: Any, ttl: Optional[timedelta] = None) -> None:
        """Store value in cache"""
        ttl = ttl or self.default_ttl

        # Remove expired entries if cache is full
        if len(self._cache) >= self.max_size:
            self._cleanup_expired()

        # If still full, remove oldest entry
        if len(self._cache) >= self.max_size:
            oldest_key = min(
                self._cache.keys(),
                key=lambda k: self._cache[k].created_at,
            )
            del self._cache[oldest_key]
            logger.debug(f"Cache evicted oldest entry: {oldest_key}")

        self._cache[key] = CacheEntry(value, ttl)
        logger.debug(f"Cache set: {key} (ttl={ttl.total_seconds():.0f}s)")

    def get(self, key: str) -> Optional[Any]:
        """Retrieve value from cache"""
        if key not in self._cache:
            self.misses += 1
            logger.debug(f"Cache miss: {key}")
            return None

        entry = self._cache[key]

        if entry.is_expired():
            del self._cache[key]
            self.misses += 1
            logger.debug(f"Cache expired: {key}")
            return None

        self.hits += 1
        logger.debug(f"Cache hit: {key}")
        return entry.value

    def invalidate(self, key: str) -> None:
        """Remove specific entry from cache"""
        if key in self._cache:
            del self._cache[key]
            logger.debug(f"Cache invalidated: {key}")

    def invalidate_all(self) -> None:
        """Clear entire cache"""
        count = len(self._cache)
        self._cache.clear()
        logger.info(f"Cache cleared ({count} entries removed)")

    def _cleanup_expired(self) -> None:
        """Remove all expired entries"""
        expired_keys = [
            key for key, entry in self._cache.items() if entry.is_expired()
        ]
        for key in expired_keys:
            del self._cache[key]
        if expired_keys:
            logger.debug(f"Cache cleaned: {len(expired_keys)} expired entries removed")

    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        self._cleanup_expired()
        total_requests = self.hits + self.misses
        hit_rate = (
            (self.hits / total_requests * 100) if total_requests > 0 else 0
        )

        return {
            "size": len(self._cache),
            "max_size": self.max_size,
            "hits": self.hits,
            "misses": self.misses,
            "hit_rate": f"{hit_rate:.1f}%",
            "total_requests": total_requests,
        }

    def __len__(self) -> int:
        """Get current cache size"""
        self._cleanup_expired()
        return len(self._cache)

    def __repr__(self) -> str:
        stats = self.get_stats()
        return f"<CacheManager size={stats['size']}/{stats['max_size']} hit_rate={stats['hit_rate']}>"
