// -*- coding: utf-8; -*-
// Package HStateTable.CellTrait.Bool
HStateTable.CellTrait.Bool = (function() {
   let bool_false = '✗';
   let bool_true  = '✓';
   return {
      initialise: function() {
         const options = this.column.options;
         if (options.bool_false) bool_false = options.bool_false;
         if (options.bool_true)  bool_true  = options.bool_true;
      },
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            if (!result.value || result.value.length == 0 || result.value == 0){
               result.value = bool_false;
            }
            else result.value = bool_true;
            return result;
         }
      }
   };
})();
// Package HStateTable.CellTrait.Capitalise
HStateTable.CellTrait.Capitalise = (function() {
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            result.value = this.capitalise(result.value);
            return result;
         }
      }
   };
})();
// Package HStateTable.CellTrait.Checkbox
HStateTable.CellTrait.Checkbox = (function() {
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            const col = this.column;
            this.appendValue(attr, 'className', 'checkbox');
            if (col.width) this.appendValue(attr, 'style', col.width);
            const handler = function(event) {
               col.table[col.table.formControl.control]();
            }.bind(this);
            const name = col.name + '.' + this.row.index;
            const box = this.h.checkbox({
               id: name, name: name, onclick: handler, value: result.value
            });
            col.rowSelector[name] = box;
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
            const result = orig(attr);
            result.value = new Date(result.value).toLocaleDateString();
            return result;
         }
      }
   };
})();
// Package HStateTable.CellTrait.DateTime
HStateTable.CellTrait.DateTime = (function() {
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            const datetime = new Date(result.value);
            const date = datetime.toLocaleDateString();
            if (date != 'Invalid Date') {
               const options = { hour: "2-digit", minute: "2-digit" };
               const time = datetime.toLocaleTimeString([], options);
               result.value = date + ' ' + time;
            }
            return result;
         }
      }
   };
})();
// Package HStateTable.CellTrait.Numeric
HStateTable.CellTrait.Numeric = (function() {
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            this.appendValue(attr, 'className', 'number');
            return result;
         }
      }
   };
})();
// Package HStateTable.CellTrait.Tagable
HStateTable.CellTrait.Tagable = (function() {
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            if (!result.tags || !result.tags[0]) return result;
            const table = this.column.table;
            const searchColumn = table.tagControl.searchColumn;
            const rs = table.resultset;
            const handler = function(tag) {
               return function(event) {
                  event.preventDefault();
                  rs.search({
                     searchColumn: searchColumn, searchValue: tag
                  }).redraw();
               };
            };
            const content = this.h.ul({ className: 'cell-content-append' });
            for (const tag of result.tags) {
               const arrow = this.h.span({ className: 'tag-arrow-left' });
               const value = this.h.span({
                  className: 'tag-value', onclick: handler(tag)
               }, tag);
               content.append(
                  this.h.li({ className: 'cell-tag' }, [arrow, value])
               );
            }
            result.append = content;
            return result;
         }
      }
   };
})();
// Package HStateTable.CellTrait.Time
HStateTable.CellTrait.Time = (function() {
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            const options = { hour: "2-digit", minute: "2-digit" };
            result.value
               = new Date(result.value).toLocaleTimeString([], options);
            return result;
         }
      }
   };
})();
