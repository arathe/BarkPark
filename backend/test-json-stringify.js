// Test JSON.stringify behavior with arrays
console.log('Testing JSON.stringify with arrays:\n');

const testCases = [
  { name: 'Empty array', value: [] },
  { name: 'Array with strings', value: ['fetch', 'swimming'] },
  { name: 'Undefined', value: undefined },
  { name: 'Null', value: null },
  { name: 'Already stringified', value: '["fetch", "swimming"]' }
];

testCases.forEach(test => {
  console.log(`${test.name}:`);
  console.log(`  Input: ${test.value}`);
  console.log(`  Type: ${typeof test.value}`);
  console.log(`  Stringified: ${JSON.stringify(test.value)}`);
  console.log(`  For SQL: ${JSON.stringify(test.value || [])}`);
  console.log('');
});