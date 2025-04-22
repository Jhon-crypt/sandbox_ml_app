const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function checkRInstallation() {
  try {
    const rVersion = execSync('R --version').toString();
    console.log('R is installed:');
    console.log(rVersion.split('\n')[0]);
    return true;
  } catch (error) {
    console.error('R is not installed or not in PATH');
    return false;
  }
}

function checkRPackages() {
  const requiredPackages = [
    "shiny", "cluster", "factoextra", "dplyr", "shinyFiles", "ggplot2", "fs",
    "DT", "markdown", "naniar", "missRanger", "readr", "gridExtra", "rlang",
    "randomForest", "caret", "pROC", "shinyjs"
  ];
  
  console.log('\nChecking for required R packages:');
  
  try {
    // Create a temporary R script to check packages
    const tempScriptPath = path.join(__dirname, 'check_packages.R');
    const scriptContent = `
    required <- c(${requiredPackages.map(p => `"${p}"`).join(', ')})
    installed <- installed.packages()[, "Package"]
    missing <- required[!required %in% installed]
    if (length(missing) > 0) {
      cat("MISSING:", paste(missing, collapse=", "), "\\n")
      quit(status = 1)
    } else {
      cat("All required R packages are installed.\\n")
      quit(status = 0)
    }
    `;
    
    fs.writeFileSync(tempScriptPath, scriptContent);
    
    // Execute the R script
    execSync(`R --vanilla -f ${tempScriptPath}`);
    console.log('All required R packages are installed');
    
    // Clean up
    fs.unlinkSync(tempScriptPath);
    return true;
  } catch (error) {
    console.error('Some required R packages are missing:', error.stdout?.toString());
    return false;
  }
}

function main() {
  console.log('Checking R environment for SandboxML packaging...');
  
  const hasR = checkRInstallation();
  const hasPackages = hasR ? checkRPackages() : false;
  
  if (!hasR) {
    console.error('\nError: R must be installed to package SandboxML.');
    console.log('Please install R from https://cran.r-project.org/');
    process.exit(1);
  }
  
  if (!hasPackages) {
    console.error('\nError: Missing required R packages.');
    console.log('Please install the missing packages using:');
    console.log('R -e "install.packages(c(\\"shiny\\", \\"cluster\\", \\"factoextra\\", \\"dplyr\\", \\"shinyFiles\\", \\"ggplot2\\", \\"fs\\", \\"DT\\", \\"markdown\\", \\"naniar\\", \\"missRanger\\", \\"readr\\", \\"gridExtra\\", \\"rlang\\", \\"randomForest\\", \\"caret\\", \\"pROC\\", \\"shinyjs\\"))"');
    process.exit(1);
  }
  
  console.log('\nR environment check passed! Ready to package SandboxML.');
}

// Run the main function if this script is executed directly
if (require.main === module) {
  main();
}

module.exports = {
  checkRInstallation,
  checkRPackages
}; 