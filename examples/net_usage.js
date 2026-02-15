const path = require('path');
const net = require(path.join(__dirname, '../packages/nyx-net/index'));

async function main() {
    console.log('--- Testing nyx-net GET ---');
    try {
        // Note: This performs a real network request
        const response = await net.get('https://www.google.com');
        console.log(`Status: ${response.status}`);
        console.log(`Body length: ${response.body.length}`);
    } catch (err) {
        console.error('GET Request failed:', err.message);
    }

    console.log('\n--- Testing nyx-net POST ---');
    try {
        // This uses the mock implementation
        const response = await net.post('https://api.example.com/resource', { id: 123 });
        console.log(`Status: ${response.status}`);
        console.log(`Body: ${response.body}`);
    } catch (err) {
        console.error('POST Request failed:', err.message);
    }
}

main();