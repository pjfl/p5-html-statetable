// Package HStateTable.Util
if (!window.HStateTable) window.HStateTable = {};
HStateTable.Util = (function () {
   const appendValue = function(object, key, newValue) {
      let existingValue = object[key] || '';
      if (existingValue) existingValue += ' ';
      return existingValue + newValue;
   };
   const onReady = function(callback) {
      if (document.readyState != 'loading') callback();
      else if (document.addEventListener)
         document.addEventListener('DOMContentLoaded', callback);
      else document.attachEvent('onreadystatechange', function() {
         if (document.readyState == 'complete') callback();
      });
   };

   return {
      appendValue: appendValue,
      onReady: onReady
   };
})();
