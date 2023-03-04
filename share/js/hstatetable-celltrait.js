// Package HStateTable.CellTrait.Checkbox
HStateTable.CellTrait.Checkbox = (function() {
   return {
      around: {
         getValue: function(orig, attr) {
            const cell = orig();
            attr.className = this.appendValue(attr.className, 'checkbox');
            if (this.column.width)
               attr.style = this.appendValue(attr.style, this.column.width);
            const name = this.column.name + '.' + this.row.index;
            const box = this.h.input({
               id: name, name: name, type: 'checkbox', value: cell.value
            });
            this.column.rowSelector[name] = box;
            return { value: box };
         }
      }
   };
})();
// Package HStateTable.CellTrait.Date
HStateTable.CellTrait.Date = (function() {
   return {
      around: {
         getValue: function(orig, attr) {
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
         getValue: function(orig, attr) {
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
         getValue: function(orig, attr) {
            const cell = orig();
            attr.className = this.appendValue(attr.className, 'number');
            return cell;
         }
      }
   };
})();
// Package HStateTable.CellTrait.Time
HStateTable.CellTrait.Time = (function() {
   return {
      around: {
         getValue: function(orig, attr) {
            const cell = orig();
            const options = { hour: "2-digit", minute: "2-digit" };
            cell.value = new Date(cell.value).toLocaleTimeString([], options);
            return cell;
         }
      }
   };
})();
