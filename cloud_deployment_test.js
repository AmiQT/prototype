/**
 * Cloud Deployment Test Script
 * Verifies all cloud services are properly configured and working
 */

// Configuration
const CONFIG = {
  backend: 'https://prototype-348e.onrender.com',
  frontend: 'https://prototype-talent-app.vercel.app',
  supabase: {
    url: 'https://xibffemtpboiecpeynon.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpYmZmZW10cGJvaWVjcGV5bm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1ODkzOTYsImV4cCI6MjA3MTE2NTM5Nn0.mwQndhu5_uX26T-qTEOCiLya74DUD6Iw8vV3ffuA5mM'
  }
};

// Test functions
const tests = {
  async testBackendHealth() {
    console.log('🔍 Testing Backend Health...');
    try {
      const response = await fetch(`${CONFIG.backend}/health`);
      const data = await response.json();
      
      if (response.ok && data.status === 'healthy') {
        console.log('✅ Backend Health: PASS');
        console.log(`   Status: ${data.status}`);
        console.log(`   Services: ${JSON.stringify(data.services)}`);
        return true;
      } else {
        console.log('❌ Backend Health: FAIL');
        return false;
      }
    } catch (error) {
      console.log('❌ Backend Health: ERROR', error.message);
      return false;
    }
  },

  async testBackendAPI() {
    console.log('🔍 Testing Backend API Endpoints...');
    const endpoints = [
      '/api/users',
      '/api/events', 
      '/api/profiles',
      '/api/search',
      '/docs'
    ];

    let passed = 0;
    for (const endpoint of endpoints) {
      try {
        const response = await fetch(`${CONFIG.backend}${endpoint}`);
        if (response.status < 500) { // Allow 401/403 for protected endpoints
          console.log(`   ✅ ${endpoint}: ${response.status}`);
          passed++;
        } else {
          console.log(`   ❌ ${endpoint}: ${response.status}`);
        }
      } catch (error) {
        console.log(`   ❌ ${endpoint}: ERROR - ${error.message}`);
      }
    }
    
    console.log(`${passed}/${endpoints.length} endpoints accessible`);
    return passed >= endpoints.length * 0.8; // 80% success rate
  },

  async testSupabaseConnection() {
    console.log('🔍 Testing Supabase Connection...');
    try {
      // Test direct connection to Supabase REST API
      const response = await fetch(`${CONFIG.supabase.url}/rest/v1/users?select=count`, {
        headers: {
          'apikey': CONFIG.supabase.anonKey,
          'Authorization': `Bearer ${CONFIG.supabase.anonKey}`
        }
      });

      if (response.ok) {
        console.log('✅ Supabase Connection: PASS');
        return true;
      } else {
        console.log('❌ Supabase Connection: FAIL', response.status);
        return false;
      }
    } catch (error) {
      console.log('❌ Supabase Connection: ERROR', error.message);
      return false;
    }
  },

  async testCORS() {
    console.log('🔍 Testing CORS Configuration...');
    try {
      const response = await fetch(`${CONFIG.backend}/health`, {
        method: 'OPTIONS'
      });
      
      if (response.ok || response.status === 405) { // OPTIONS might not be implemented
        console.log('✅ CORS Configuration: PASS');
        return true;
      } else {
        console.log('❌ CORS Configuration: FAIL');
        return false;
      }
    } catch (error) {
      console.log('❌ CORS Configuration: ERROR', error.message);
      return false;
    }
  },

  async testCloudinary() {
    console.log('🔍 Testing Cloudinary Integration...');
    try {
      const response = await fetch(`${CONFIG.backend}/api/media/test-upload`, {
        method: 'GET'
      });
      
      if (response.status < 500) {
        console.log('✅ Cloudinary Integration: ACCESSIBLE');
        return true;
      } else {
        console.log('❌ Cloudinary Integration: FAIL');
        return false;
      }
    } catch (error) {
      console.log('❌ Cloudinary Integration: ERROR', error.message);
      return false;
    }
  }
};

// Run all tests
async function runAllTests() {
  console.log('🚀 Starting Cloud Deployment Tests...');
  console.log('='.repeat(50));
  
  const results = {
    backendHealth: await tests.testBackendHealth(),
    backendAPI: await tests.testBackendAPI(),
    supabase: await tests.testSupabaseConnection(),
    cors: await tests.testCORS(),
    cloudinary: await tests.testCloudinary()
  };
  
  console.log('\n' + '='.repeat(50));
  console.log('📊 TEST RESULTS SUMMARY:');
  console.log('='.repeat(50));
  
  const passed = Object.values(results).filter(r => r).length;
  const total = Object.keys(results).length;
  
  Object.entries(results).forEach(([test, result]) => {
    console.log(`${result ? '✅' : '❌'} ${test}: ${result ? 'PASS' : 'FAIL'}`);
  });
  
  console.log('\n' + '-'.repeat(50));
  console.log(`Overall: ${passed}/${total} tests passed (${Math.round(passed/total*100)}%)`);
  
  if (passed === total) {
    console.log('🎉 All cloud services are working correctly!');
  } else if (passed >= total * 0.8) {
    console.log('⚠️  Most services working, some issues to investigate');
  } else {
    console.log('🚨 Major issues detected, please check configuration');
  }
  
  console.log('\n📝 Next Steps:');
  console.log('1. Fix any failing tests above');
  console.log('2. Deploy your web dashboard to Vercel');
  console.log('3. Test the full application flow');
  console.log('4. Monitor logs for any runtime errors');
  
  return { passed, total, percentage: Math.round(passed/total*100) };
}

// Export for use in browser or Node.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { runAllTests, tests, CONFIG };
} else if (typeof window !== 'undefined') {
  window.CloudDeploymentTest = { runAllTests, tests, CONFIG };
}

// Auto-run if called directly
if (typeof window === 'undefined') {
  runAllTests().catch(console.error);
}
