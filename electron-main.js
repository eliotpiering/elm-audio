var fs = require('fs');
var electron = require('electron');

var app = electron.app;
var BrowserWindow = electron.BrowserWindow;

var mainWindow = null;

// Quit when all windows are closed.
app.on('window-all-closed', function() {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform != 'darwin') {
    app.quit();
  }
});

app.on('ready', function() {
  mainWindow = new BrowserWindow({fullScreen: false});
	mainWindow.on('app-command', (e, cmd) => {
		// Navigate the window back when the user hits their mouse back button
		if (cmd === 'browser-backward' && mainWindow.webContents.canGoBack()) {
			mainWindow.webContents.goBack();
		}
  });

  mainWindow.loadURL('file://' + __dirname + '/index.html');

  var initialData = listDirectory('/home/eliot/Music');
  mainWindow.webContents.on('did-finish-load', function () {
    mainWindow.webContents.send('listDirectory', initialData);
  });

  electron.ipcMain.on('list-new-directory', function(_event, basePath){
    var data = listDirectory(basePath);
    mainWindow.webContents.send('listDirectory', data);
  });

  mainWindow.on('closed', function() {
    mainWindow = null;
  });

});

function listDirectory(basePath) {
  console.log(basePath);
  var filesAndSubDirs = fs.readdirSync(basePath);
  var directories = [];
  var files = [];
  filesAndSubDirs.forEach(function(f){
    var fullPath = basePath + '/' + f;

    var stat = fs.statSync(fullPath);
    var statObject = {name: f, path: fullPath};
    if (stat.isDirectory()) {
      directories.push(statObject);
    } else if (stat.isFile()) {
      files.push(statObject);
    }
  });
  var dataObject = {
    subDirs: directories,
    files: files
  };
  return dataObject;
}
