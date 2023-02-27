// Package HStateTable.CellTrait.Date
HStateTable.CellTrait.Date = (function() {
   return {
      around: {
         getValue: function(orig) {
            const cell = orig();
            cell.value = new Date(cell.value).toLocaleDateString();
            return cell;
         }
      }
   };
})();
// Package HStateTable.CellTrait.DateTime
HStateTable.CellTrait.DateTime = (function() {
   return {
      around: {
         getValue: function(orig) {
            const cell = orig();
            const datetime = new Date(cell.value);
            const date = datetime.toLocaleDateString();
            const options = { hour: "2-digit", minute: "2-digit" };
            const time = datetime.toLocaleTimeString([], options);
            cell.value = date + ' ' + time;
            return cell;
         }
      }
   };
})();
// Package HStateTable.CellTrait.Numeric
HStateTable.CellTrait.Numeric = (function() {
   return {
      around: {
         getValue: function(orig) {
            const cell = orig();
            cell.wrapperClass = this.appendValue('wrapperClass', 'number');
            return cell;
         }
      }
   };
})();
// Package HStateTable.CellTrait.Time
HStateTable.CellTrait.Time = (function() {
   return {
      around: {
         getValue: function(orig) {
            const cell = orig();
            const options = { hour: "2-digit", minute: "2-digit" };
            cell.value = new Date(cell.value).toLocaleTimeString([], options);
            return cell;
         }
      }
   };
})();
