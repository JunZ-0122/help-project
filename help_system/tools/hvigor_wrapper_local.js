const fs = require('fs');
const path = require('path');

const ORIGINAL_HVIGOR_WRAPPER = 'D:\\Huawei\\DevEco Studio\\tools\\hvigor\\bin\\hvigorw.js';

function removeIfExists(targetPath) {
  if (fs.existsSync(targetPath)) {
    fs.rmSync(targetPath, { recursive: true, force: true });
  }
}

function copyInsteadOfLink(sourcePath, targetPath) {
  const stat = fs.statSync(sourcePath);
  removeIfExists(targetPath);

  if (stat.isDirectory()) {
    fs.cpSync(sourcePath, targetPath, { recursive: true });
    return;
  }

  fs.mkdirSync(path.dirname(targetPath), { recursive: true });
  fs.copyFileSync(sourcePath, targetPath);
}

const originalSymlinkSync = fs.symlinkSync.bind(fs);
fs.symlinkSync = (sourcePath, targetPath, type) => {
  try {
    copyInsteadOfLink(sourcePath, targetPath);
  } catch (error) {
    originalSymlinkSync(sourcePath, targetPath, type);
  }
};

const originalSymlink = fs.symlink.bind(fs);
fs.symlink = (sourcePath, targetPath, type, callback) => {
  let actualType = type;
  let actualCallback = callback;

  if (typeof type === 'function') {
    actualCallback = type;
    actualType = undefined;
  }

  try {
    copyInsteadOfLink(sourcePath, targetPath);
    if (actualCallback) {
      actualCallback(null);
    }
  } catch (error) {
    originalSymlink(sourcePath, targetPath, actualType, actualCallback);
  }
};

if (fs.promises && fs.promises.symlink) {
  const originalPromiseSymlink = fs.promises.symlink.bind(fs.promises);
  fs.promises.symlink = async (sourcePath, targetPath, type) => {
    try {
      copyInsteadOfLink(sourcePath, targetPath);
    } catch (error) {
      await originalPromiseSymlink(sourcePath, targetPath, type);
    }
  };
}

require(ORIGINAL_HVIGOR_WRAPPER);
