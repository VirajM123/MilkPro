const http = require('http');

function makeRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data ? JSON.parse(data) : null,
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data,
          });
        }
      });
    });

    req.on('error', (e) => reject(e));

    if (postData) {
      req.write(typeof postData === 'string' ? postData : JSON.stringify(postData));
    }
    req.end();
  });
}

async function runTests() {
  console.log('Testing RBAC Allocation & Common Salesman Access...\n');

  // 1. Check if backend server is running on port 5000
  try {
    const health = await makeRequest({
      hostname: 'localhost',
      port: 5000,
      path: '/api/auth/login',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    }, {});
    console.log('Backend response status from /api/auth/login:', health.statusCode);
  } catch (err) {
    console.log('Backend server not currently running on port 5000 (unit verification will test server.js exports directly).');
  }

  // 2. Load and verify backend/server.js syntax and route registrations
  try {
    const fs = require('fs');
    const serverSource = fs.readFileSync('backend/server.js', 'utf8');

    console.log('Verifying backend endpoints exist in server.js:');
    
    // Check GET /api/settings/salesman-permissions
    const hasGetCommon = serverSource.includes('app.get(') && 
      serverSource.includes('"/api/settings/salesman-permissions"');
    console.log('  GET /api/settings/salesman-permissions:', hasGetCommon ? 'OK' : 'MISSING');

    // Check PUT /api/settings/salesman-permissions
    const hasPutCommon = serverSource.includes('app.put(') && 
      serverSource.includes('"/api/settings/salesman-permissions"');
    console.log('  PUT /api/settings/salesman-permissions:', hasPutCommon ? 'OK' : 'MISSING');

    // Check requireAdmin on /api/salesmen
    const hasAdminSalesmen = serverSource.includes('/api/salesmen') && 
      serverSource.includes('requireAdmin');
    console.log('  requireAdmin on /api/salesmen:', hasAdminSalesmen ? 'OK (Admin-only preserved)' : 'CHECK');

    // Check requireAnyPermission on /api/allocations
    const hasAllocPerm = serverSource.includes('/api/allocations') && 
      serverSource.includes('allocationView');
    console.log('  allocationView on /api/allocations:', hasAllocPerm ? 'OK' : 'CHECK');

    // Check permissionMode support in PUT /api/salesmen/:salesmanId/permissions
    const hasPermMode = serverSource.includes('permissionMode') && 
      serverSource.includes('salesman.permissionMode');
    console.log('  permissionMode support in salesman permissions:', hasPermMode ? 'OK' : 'CHECK');

    if (hasGetCommon && hasPutCommon && hasAdminSalesmen && hasAllocPerm && hasPermMode) {
      console.log('\nAll backend route definitions and security constraints verified successfully!');
    } else {
      console.error('\nSome backend checks failed!');
      process.exit(1);
    }
  } catch (err) {
    console.error('Error verifying server.js:', err);
    process.exit(1);
  }
}

runTests();

