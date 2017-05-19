  var exec = require('cordova/exec');

  var NaverPlugin = {
    login: function (successCallback, failCallback) {
      exec(successCallback, failCallback, "NaverPlugin", "login", []);
    },
    logout: function (successCallback, failCallback) {
      exec(successCallback, failCallback, "NaverPlugin", "logout", []);
    }
  };

  module.exports = NaverPlugin;
