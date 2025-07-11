const { execSync } = require('child_process');

try {
  // Change to the project directory
  process.chdir('/Users/austinrathe/Documents/Developer/BarkPark');
  
  // Get git status
  const status = execSync('git status --porcelain', { encoding: 'utf8' });
  
  if (status) {
    console.log('Modified/Untracked files:');
    console.log(status);
  } else {
    console.log('Working tree is clean');
  }
  
  // Get last commit
  const lastCommit = execSync('git log -1 --oneline', { encoding: 'utf8' });
  console.log('\nLast commit:', lastCommit.trim());
  
  // Check if we need to push
  const unpushed = execSync('git status -sb', { encoding: 'utf8' });
  console.log('\nBranch status:', unpushed.trim());
  
} catch (error) {
  console.error('Error:', error.message);
}