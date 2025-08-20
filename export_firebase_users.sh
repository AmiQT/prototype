#!/bin/bash

# Firebase User Export Script
# Run this script to export your Firebase users

echo "🔥 Exporting Firebase Users..."

# Make sure you're logged into Firebase CLI
echo "Checking Firebase CLI login..."
firebase login --reauth

# Export users from your Firebase project
echo "Exporting users from project: student-talent-profiling-eaede"
firebase auth:export firebase_users.json --project student-talent-profiling-eaede

# Check if export was successful
if [ -f "firebase_users.json" ]; then
    echo "✅ Users exported successfully to firebase_users.json"
    echo "📊 Checking user count..."
    
    # Count users in the exported file
    user_count=$(jq '.users | length' firebase_users.json 2>/dev/null || echo "Install jq to see user count")
    echo "👥 Exported users: $user_count"
    
    echo ""
    echo "📋 Next steps:"
    echo "1. Review the exported firebase_users.json file"
    echo "2. Run the Supabase import script"
    echo "3. Test authentication with migrated users"
else
    echo "❌ Export failed. Please check your Firebase project ID and permissions."
fi