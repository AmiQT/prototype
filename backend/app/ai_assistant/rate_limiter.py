"""Simple rate limiter untuk Gemini API calls"""

import time
from collections import deque
from typing import Dict
import logging

logger = logging.getLogger(__name__)

class SimpleRateLimiter:
    """Simple in-memory rate limiter untuk API calls"""
    
    def __init__(self, max_requests: int = 10, time_window: int = 60):
        """
        Initialize rate limiter
        
        Args:
            max_requests: Maximum requests allowed in time window
            time_window: Time window in seconds (default 60s = 1 minute)
        """
        self.max_requests = max_requests
        self.time_window = time_window
        self.requests: Dict[str, deque] = {}  # user_id -> timestamps
        
    def can_make_request(self, user_id: str) -> bool:
        """
        Check if user can make a request
        
        Args:
            user_id: Unique identifier for user
            
        Returns:
            True if request is allowed, False otherwise
        """
        current_time = time.time()
        
        # Initialize user's request queue if not exists
        if user_id not in self.requests:
            self.requests[user_id] = deque()
        
        user_requests = self.requests[user_id]
        
        # Remove old requests outside time window
        while user_requests and current_time - user_requests[0] > self.time_window:
            user_requests.popleft()
        
        # Check if under limit
        if len(user_requests) < self.max_requests:
            user_requests.append(current_time)
            logger.info(f"✅ Rate limit OK for {user_id}: {len(user_requests)}/{self.max_requests} in {self.time_window}s")
            return True
        else:
            logger.warning(f"⚠️  Rate limit exceeded for {user_id}: {len(user_requests)}/{self.max_requests} in {self.time_window}s")
            return False
    
    def get_wait_time(self, user_id: str) -> float:
        """
        Get how long user needs to wait before next request
        
        Args:
            user_id: Unique identifier for user
            
        Returns:
            Wait time in seconds, 0 if can make request immediately
        """
        if user_id not in self.requests or not self.requests[user_id]:
            return 0.0
        
        current_time = time.time()
        user_requests = self.requests[user_id]
        
        # Remove old requests
        while user_requests and current_time - user_requests[0] > self.time_window:
            user_requests.popleft()
        
        # If under limit, no wait needed
        if len(user_requests) < self.max_requests:
            return 0.0
        
        # Calculate wait time until oldest request expires
        oldest_request = user_requests[0]
        wait_time = self.time_window - (current_time - oldest_request)
        return max(0.0, wait_time)
    
    def reset_user(self, user_id: str):
        """Reset rate limit for specific user"""
        if user_id in self.requests:
            del self.requests[user_id]
            logger.info(f"🔄 Rate limit reset for {user_id}")

# Global rate limiter instance
# Gemini Free tier: 15 RPM, but we set to 10 to be safe
gemini_rate_limiter = SimpleRateLimiter(max_requests=10, time_window=60)
