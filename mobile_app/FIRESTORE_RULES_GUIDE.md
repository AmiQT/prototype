# Firestore Rules Management Guide

This guide explains how to manage Firestore security rules for development vs production environments.

## The Problem

Strict Firestore security rules are essential for production but can be a major hassle during development and testing because:
- Complex permission checks can block legitimate development operations
- Debugging permission issues is time-consuming
- Rules need to be perfect before you can test basic functionality
- Collection queries often fail due to document-level permission checks

## The Solution

We've implemented a flexible rules system with multiple configurations:

### 1. Development Rules (`firestore.dev.rules`)
- **Very permissive** - allows all operations for authenticated users
- **Perfect for development and testing**
- **⚠️ NEVER use in production!**

### 2. Production Rules (`firestore.rules`)
- **Secure and strict** - proper permission checks
- **Use for production deployments**
- Has a development mode flag that can be toggled

## Quick Commands

### Switch to Development Rules (Easy Testing)
```bash
# Copy dev rules to main rules file
Copy-Item firestore.dev.rules firestore.rules -Force

# Deploy to Firebase
firebase deploy --only firestore:rules
```

### Switch to Production Rules (Secure)
```bash
# Use the PowerShell script
.\scripts\switch_rules.ps1 prod

# Or manually edit firestore.rules and set:
# function isDevelopmentMode() { return false; }

# Deploy to Firebase
firebase deploy --only firestore:rules
```

### Using the PowerShell Script
```bash
# Switch to development mode
.\scripts\switch_rules.ps1 dev

# Switch to production mode  
.\scripts\switch_rules.ps1 prod
```

## Development Workflow

1. **During Development**: Use development rules for hassle-free testing
2. **Before Production**: Switch to production rules and test thoroughly
3. **Production Deployment**: Ensure production rules are active

## Files Overview

- `firestore.rules` - Main rules file (what gets deployed)
- `firestore.dev.rules` - Development rules (very permissive)
- `firestore.rules.backup` - Backup of previous rules
- `scripts/switch_rules.ps1` - PowerShell script to switch rules
- `scripts/switch_firestore_rules.dart` - Dart script to switch rules

## Current Status

✅ **Development rules are currently active** - perfect for testing!

The app should now load posts and images without permission issues.

## Security Notes

- Development rules allow ANY authenticated user to read/write ANY document
- This is intentionally insecure for easier development
- Always switch to production rules before deploying to production
- Test thoroughly with production rules before going live

## Troubleshooting

If you're still getting permission errors:
1. Make sure you deployed the rules: `firebase deploy --only firestore:rules`
2. Wait 1-2 minutes for rules to propagate
3. Restart the app to clear any cached permission denials
4. Check the Firebase Console to verify rules are deployed
