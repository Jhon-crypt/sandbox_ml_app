const { notarize } = require('electron-notarize');
const path = require('path');
const fs = require('fs');

exports.default = async function notarizing(context) {
  // Only notarize macOS builds
  if (context.electronPlatformName !== 'darwin' || process.env.SKIP_NOTARIZE === 'true') {
    console.log('Skipping notarization');
    return;
  }

  console.log('Notarizing macOS app...');

  const appId = context.packager.appInfo.id;
  const appName = context.packager.appInfo.productFilename;
  const appPath = path.join(context.appOutDir, `${appName}.app`);

  if (!fs.existsSync(appPath)) {
    throw new Error(`Cannot find application at: ${appPath}`);
  }

  // Check for Apple ID and password in environment variables
  if (!process.env.APPLE_ID || !process.env.APPLE_ID_PASSWORD) {
    console.warn('Skipping notarization: APPLE_ID and APPLE_ID_PASSWORD env variables must be set');
    return;
  }

  try {
    await notarize({
      appBundleId: appId,
      appPath: appPath,
      appleId: process.env.APPLE_ID,
      appleIdPassword: process.env.APPLE_ID_PASSWORD,
    });
    console.log(`Successfully notarized ${appName}`);
  } catch (error) {
    console.error('Notarization failed:', error);
    throw error;
  }
}; 