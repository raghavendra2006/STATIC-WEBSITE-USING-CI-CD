document.addEventListener('DOMContentLoaded', () => {
  // Theme Toggle Logic
  const themeToggle = document.getElementById('themeToggle');
  const themeIcon = document.getElementById('themeIcon');
  
  // Set theme from local storage or system preference
  const savedTheme = localStorage.getItem('theme') || 
    (window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');
  
  document.documentElement.setAttribute('data-theme', savedTheme);
  updateThemeIcon(savedTheme);

  themeToggle.addEventListener('click', () => {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    updateThemeIcon(newTheme);
  });

  function updateThemeIcon(theme) {
    if (theme === 'light') {
      themeIcon.innerHTML = '🌙'; // Icon for changing to dark mode
    } else {
      themeIcon.innerHTML = '☀️'; // Icon for changing to light mode
    }
  }

  // Interactive Pipeline Demo Logic
  const steps = document.querySelectorAll('.pipeline-step');
  const connectors = document.querySelectorAll('.pipeline-connector');
  const consoleContent = document.getElementById('consoleContent');

  const stepDetails = {
    1: {
      name: 'Trigger & Checkout',
      logs: [
        '[CI] Triggered by push to branch main',
        '[CI] Git SHA: a8d5f3c (Latest commit info)',
        '[CI] Checking out repository...',
        '[CI] Finished repository checkout. Code available at workspace.'
      ]
    },
    2: {
      name: 'Install & Build',
      logs: [
        '$ npm ci --prefer-offline',
        'added 241 packages in 3.42s',
        '$ npm run build',
        'vite v5.3.3 building for production...',
        'dist/index.html            1.82 kB │ gzip: 0.74 kB',
        'dist/about.html            1.54 kB │ gzip: 0.65 kB',
        'dist/assets/index-D7b3.js  42.50 kB │ gzip: 14.10 kB',
        'dist/assets/index-C8g2.css 12.12 kB │ gzip: 3.40 kB',
        '✓ built in 820ms'
      ]
    },
    3: {
      name: 'Lint Codebase',
      logs: [
        '$ npm run lint',
        'Running htmlhint on 2 HTML files... Pass!',
        'Running stylelint on style.css... Pass!',
        'Running eslint on main.js... Pass!',
        '✔ Codebase matches style guide and quality constraints.'
      ]
    },
    4: {
      name: 'E2E Testing',
      logs: [
        '$ npx playwright test',
        'Running 3 tests using 1 worker',
        '  ✓ [chromium] › smoke.test.js:12:3 › Home page loads successfully (250ms)',
        '  ✓ [chromium] › smoke.test.js:20:3 › About page loads successfully (190ms)',
        '  ✓ [chromium] › smoke.test.js:28:3 › Theme toggle updates data-theme attribute (150ms)',
        '  3 passed (620ms)'
      ]
    },
    5: {
      name: 'Security Scan',
      logs: [
        '$ npm audit --audit-level=high',
        'found 0 vulnerabilities (241 packages scanned)',
        '$ trivy fs --severity HIGH,CRITICAL dist/',
        '2026-06-28T20:32:00Z INFO Vulnerability scanning is enabled',
        'dist/ (filesystem)',
        '==================',
        'Total: 0 (HIGH: 0, CRITICAL: 0)',
        '✔ Security scans passed successfully.'
      ]
    },
    6: {
      name: 'Package Artifact',
      logs: [
        'Archiving build output from dist/ directory...',
        'Creating artifact build-a8d5f3c.tar.gz',
        'Uploading build artifact to GitHub Artifact Store...',
        'Artifact uploaded successfully. Artifact ID: 8941753'
      ]
    },
    7: {
      name: 'Staging Deploy',
      logs: [
        '$ aws s3 sync dist/ s3://staging-static-website-bucket/',
        'upload: dist/index.html to s3://staging-static-website-bucket/index.html',
        'upload: dist/about.html to s3://staging-static-website-bucket/about.html',
        '$ aws cloudfront create-invalidation --distribution-id E2STG12345 --paths "/*"',
        'Invalidation created. Invalidation ID: I2P5J1STG',
        'Smoke checking staging deployment: https://staging.cloudfront.net/',
        'HTTP GET / -> 200 OK (Verifying content matches current commit)... Pass!'
      ]
    },
    8: {
      name: 'Prod Deploy',
      logs: [
        'Checking active environment marker in AWS SSM...',
        'Current active environment is: BLUE',
        'Deploying new build to inactive environment: GREEN',
        '$ aws s3 sync dist/ s3://prod-green-static-website-bucket/',
        'upload: dist/index.html to s3://prod-green-static-website-bucket/index.html',
        'Smoke checking inactive green environment... Pass!',
        'Updating CloudFront distribution E3PROD12345 to green origin...',
        'Distribution update requested. Invalidation ID: I3P5J2PROD',
        'Updating SSM Parameter /site/prod-active-color to: green',
        '✔ Deployment to Production (GREEN) completed successfully.',
        'Rollback command: scripts/rollback.sh'
      ]
    }
  };

  function displayLogs(stepIndex) {
    const details = stepDetails[stepIndex];
    if (!details) return;

    consoleContent.innerHTML = '';
    
    // Simulate line-by-line typing with delay
    let lineIdx = 0;
    function printNextLine() {
      if (lineIdx < details.logs.length) {
        const line = document.createElement('div');
        line.textContent = details.logs[lineIdx];
        if (details.logs[lineIdx].startsWith('$')) {
          line.style.color = '#38bdf8'; // Sky blue for commands
        } else if (details.logs[lineIdx].includes('✓') || details.logs[lineIdx].includes('✔') || details.logs[lineIdx].includes('passed') || details.logs[lineIdx].includes('Pass!')) {
          line.style.color = '#34d399'; // Emerald green for success
        } else if (details.logs[lineIdx].includes('Error') || details.logs[lineIdx].includes('fail')) {
          line.style.color = '#f87171'; // Red for failures
        }
        consoleContent.appendChild(line);
        lineIdx++;
        setTimeout(printNextLine, 120);
      } else {
        const cursor = document.createElement('span');
        cursor.className = 'console-cursor';
        consoleContent.appendChild(cursor);
      }
    }
    printNextLine();
  }

  steps.forEach(step => {
    step.addEventListener('click', () => {
      const stepIdx = parseInt(step.getAttribute('data-step'), 10);
      
      // Update UI active states
      steps.forEach((s, idx) => {
        const sIdx = idx + 1;
        s.classList.remove('active', 'success');
        if (sIdx < stepIdx) {
          s.classList.add('success');
        } else if (sIdx === stepIdx) {
          s.classList.add('active');
        }
      });

      // Update connector states
      connectors.forEach((conn, idx) => {
        const connIdx = idx + 1;
        conn.classList.remove('active', 'success');
        if (connIdx < stepIdx) {
          conn.classList.add('success');
        } else if (connIdx === stepIdx) {
          conn.classList.add('active');
        }
      });

      displayLogs(stepIdx);
    });
  });

  // Load first step logs on startup
  displayLogs(1);
});
