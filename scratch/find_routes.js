const fs = require('fs');
const content = fs.readFileSync('backend/server.js', 'utf8');

console.log('=== FINDING ROUTES ===');
const regex = /app\.(get|post|put|delete|patch)\s*\(\s*["']([^"']+)["']/g;
let match;
while ((match = regex.exec(content)) !== null) {
  const lineNo = content.substring(0, match.index).split('\n').length;
  if (match[2].includes('allocation') || match[2].includes('sale') || match[2].includes('return') || match[2].includes('stock')) {
    console.log(`${lineNo}: ${match[1].toUpperCase()} ${match[2]}`);
  }
}

