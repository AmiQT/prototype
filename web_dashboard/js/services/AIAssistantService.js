import { BACKEND_CONFIG, getAuthHeaders } from '../config/backend-config.js';

const AI_CACHE = {
  quotaUsed: 0,
  quotaLimit: 50,
  lastUpdated: null,
};

// Browser-based session management for AI context
class BrowserSessionManager {
  constructor() {
    this.sessionId = this.generateSessionId();
    this.sessionKey = `ai_conversation_${this.sessionId}`;
  }

  generateSessionId() {
    // Create session ID based on timestamp and random string
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Store message in sessionStorage (cleared when browser tab closes)
  storeMessage(role, content) {
    try {
      const messages = this.getMessages() || [];
      messages.push({
        role,
        content,
        timestamp: new Date().toISOString()
      });
      
      // Keep only last 10 messages to prevent storage overflow
      if (messages.length > 10) {
        messages.splice(0, messages.length - 10);
      }
      
      sessionStorage.setItem(this.sessionKey, JSON.stringify(messages));
    } catch (error) {
      console.warn('Failed to store message in session storage:', error);
    }
  }

  getMessages() {
    try {
      const stored = sessionStorage.getItem(this.sessionKey);
      return stored ? JSON.parse(stored) : [];
    } catch (error) {
      console.warn('Failed to retrieve messages from session storage:', error);
      return [];
    }
  }

  getRecentContext(limit = 5) {
    const messages = this.getMessages();
    return messages.slice(-limit).map(msg => 
      `[${msg.role.toUpperCase()}]: ${msg.content}`
    ).join('\\n');
  }

  clearSession() {
    sessionStorage.removeItem(this.sessionKey);
  }

  getSessionId() {
    return this.sessionId;
  }
}

const sessionManager = new BrowserSessionManager();

async function fetchAI(endpoint, options = {}) {
  if (!BACKEND_CONFIG.baseUrl) {
    throw new Error('Backend base URL not configured. Please set BACKEND_CONFIG.baseUrl');
  }

  const headers = await getAuthHeaders();
  const response = await fetch(`${BACKEND_CONFIG.baseUrl}${endpoint}`, {
    method: 'POST',
    headers,
    ...options,
    body: JSON.stringify(options.body || {}),
  });

  if (!response.ok) {
    const detail = await response.json().catch(() => ({}));
    throw new Error(detail.detail || detail.message || `AI request failed (${response.status})`);
  }

  return response.json();
}

async function fetchHistory(limit = 10) {
  const headers = await getAuthHeaders();
  const response = await fetch(`${BACKEND_CONFIG.baseUrl}${BACKEND_CONFIG.endpoints.ai.history}?limit=${limit}`, {
    method: 'GET',
    headers,
  });

  if (!response.ok) {
    return { history: [] };
  }

  return response.json();
}

export const AIAssistantService = {
  async sendCommand(command) {
    // Get context from browser session storage
    const context = {
      session_id: sessionManager.getSessionId(),
      recent_conversation: sessionManager.getRecentContext(5),
      timestamp: new Date().toISOString()
    };

    const payload = { command, context };
    const result = await fetchAI(BACKEND_CONFIG.endpoints.ai.command, { body: payload });

    // Store the interaction in browser session
    sessionManager.storeMessage('user', command);
    if (result?.message) {
      sessionManager.storeMessage('assistant', result.message);
    }

    if (result?.data?.quota) {
      AI_CACHE.quotaUsed = result.data.quota.used ?? AI_CACHE.quotaUsed;
      AI_CACHE.quotaLimit = result.data.quota.limit ?? AI_CACHE.quotaLimit;
      AI_CACHE.lastUpdated = new Date().toISOString();
    }

    return result;
  },

  async getHistory(limit = 10) {
    return fetchHistory(limit);
  },

  getQuota() {
    return AI_CACHE;
  },

  setQuota({ used, limit }) {
    AI_CACHE.quotaUsed = used;
    AI_CACHE.quotaLimit = limit;
    AI_CACHE.lastUpdated = new Date().toISOString();
  },

  // Clear browser session
  clearSession() {
    sessionManager.clearSession();
  },

  // Get current session info
  getSessionInfo() {
    return {
      session_id: sessionManager.getSessionId(),
      message_count: sessionManager.getMessages().length,
      recent_context: sessionManager.getRecentContext(5)
    };
  }
};

