const path = require('path');
const fs = require('fs');

// Look for .env in several possible locations
// From scripts directory, go up 2 levels to reach project root where .env is located
const envPaths = [
  path.resolve(__dirname, '../../.env'), // Project root (scripts -> web_dashboard -> prototype)
  path.resolve(__dirname, '../../backend/.env'), // Backend root
  path.resolve(__dirname, '../../backend/.env.backup'), // Backend backup 
  path.resolve(__dirname, '../../backend/.env.cloud'), // Backend cloud
];

let foundEnvFile = false;
// Try each path until we find a valid .env file
for (const envPath of envPaths) {
  if (fs.existsSync(envPath)) {
    console.log(`dY"? Loading environment from: ${envPath}`);
    require('dotenv').config({ path: envPath });
    foundEnvFile = true;
    break;
  }
}

// If no .env file found in expected locations, check if we already have the variables in process.env
if (!process.env.SUPABASE_URL) {
  if (!foundEnvFile) {
    console.log('�s��,?  No .env file found in expected locations. Using process environment or defaults.');
  }
}

// Define the environment configuration
const envConfig = {
  SUPABASE_URL: process.env.SUPABASE_URL || 'https://xibffemtpboiecpeynon.supabase.co',
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpYmZmZW10cGJvaWVjcGV5bm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1ODkzOTYsImV4cCI6MjA3MTE2NTM5Nn0.mwQndhu5_uX26T-qTEOCiLya74DUD6Iw8vV3ffuA5mM',
  SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpYmZmZW10cGJvaWVjcGV5bm9uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNzM4MjQwNCwiZXhwIjoyMDQyOTU4NDA0fQ.cOJw3H0zZ3j8Z8b3Z3Z3Z3Z3Z3Z3Z3Z3Z3Z3Z3Z3Z3Z',
  BACKEND_URL: process.env.BACKEND_URL || 'http://127.0.0.1:8000',
  ENABLE_AI_ASSISTANT: process.env.ENABLE_AI_ASSISTANT === 'true' || true,
  ENABLE_ANALYTICS: process.env.ENABLE_ANALYTICS === 'true' || true,
};

// Create the JavaScript file content
const jsContent = `// dY"' FRONTEND ENVIRONMENT VARIABLES
// Auto-generated from .env file - DO NOT EDIT MANUALLY
// This file is in .gitignore - NEVER commit it!

window.ENV = ${JSON.stringify(envConfig, null, 2)};

console.log('Environment variables loaded:', {
  SUPABASE_URL: window.ENV.SUPABASE_URL ? 'LOADED' : 'NOT SET',
  SUPABASE_ANON_KEY: window.ENV.SUPABASE_ANON_KEY ? 'LOADED (hidden)' : 'NOT SET',
  BACKEND_URL: window.ENV.BACKEND_URL,
  ENABLE_AI_ASSISTANT: window.ENV.ENABLE_AI_ASSISTANT,
  ENABLE_ANALYTICS: window.ENV.ENABLE_ANALYTICS
});
`;

// Define the output file path
const outputPath = path.join(__dirname, '../js/config/env.js');

// Ensure the output directory exists
const outputDir = path.dirname(outputPath);
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// Write the file
fs.writeFileSync(outputPath, jsContent);

console.log(`�o. Environment configuration generated at: ${outputPath}`);
console.log('Environment variables loaded:');
console.log('- SUPABASE_URL:', envConfig.SUPABASE_URL ? '�o. Present' : '�?O Missing');
console.log('- SUPABASE_ANON_KEY:', envConfig.SUPABASE_ANON_KEY ? '�o. Present (hidden)' : '�?O Missing');
console.log('- BACKEND_URL:', envConfig.BACKEND_URL);
console.log('- ENABLE_AI_ASSISTANT:', envConfig.ENABLE_AI_ASSISTANT);
console.log('- ENABLE_ANALYTICS:', envConfig.ENABLE_ANALYTICS);

// Check if environment variables were loaded from .env file
if (foundEnvFile && process.env.SUPABASE_URL) {
  console.log('\ndYZ% Environment variables successfully loaded from .env file!');
} else if (process.env.SUPABASE_URL) {
  console.log('\ndYZ% Environment variables successfully loaded from system environment!');
} else {
  console.log('\n�s��,?  Environment variables loaded from default values. Please create a .env file with your actual configuration.');
}
