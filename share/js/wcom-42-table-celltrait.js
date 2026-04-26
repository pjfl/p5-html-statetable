/** -*- coding: utf-8; -*-
    @file HTML StateTable - Cell Traits
    @classdesc Traits applied to the cell object
    @author pjfl@cpan.org (Peter Flanigan)
    @version 0.2.35
*/
WCom.Table.CellTrait.Bool = (function() {
   let boolColours = ['firebrick', 'seagreen'];
   let boolFalse = '✗';
   let boolTrue = '✓';
   /** @mixin TableCellTrait/Bool
       @classdesc Boolean cell trait
   */
   return {
      initialise: function() {
         const options = this.column.options;
         if (options['bool-colours']) boolColours = options['bool-colours'];
         if (options['bool-false']) boolFalse = options['bool-false'];
         if (options['bool-true']) boolTrue = options['bool-true'];
      },
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            if (result.value.length == 0) return result;
            this.appendValue(attr, 'className', 'boolean');
            if (!result.value || result.value == 0) {
               this.appendValue(attr, 'style', 'color:' + boolColours[0]);
               result.value = boolFalse;
            }
            else {
               this.appendValue(attr, 'style', 'color:' + boolColours[1]);
               result.value = boolTrue;
            }
            return result;
         }
      }
   };
})();
// Package WCom.Table.CellTrait.Capitalise
WCom.Table.CellTrait.Capitalise = (function() {
   /** @mixin TableCellTrait/Capitalise
       @desc Capitalise cell trait
   */
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
// Package WCom.Table.CellTrait.Checkbox
WCom.Table.CellTrait.Checkbox = (function() {
   /** @mixin TableCellTrait/Checkbox
       @desc Checkbox cell trait
   */
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            const col = this.column;
            this.appendValue(attr, 'className', 'checkbox');
            if (col.width) this.appendValue(attr, 'style', col.width);
            const onclick = function(event) {
               if (col.table.formControl) col.table.formControl.renderAll();
            }.bind(this);
            let name = col.name;
            if (col.options['select-one']) {
               const id = name + '.' + this.row.index;
               const options = { id, name, onclick, value: result.value };
               const box = this.h.radio(options);
               col.rowSelector[id] = box;
               return { value: box };
            }

            name += '.' + this.row.index;
            const options = { id: name, name, onclick, value: result.value };
            const box = this.h.checkbox(options);
            col.rowSelector[name] = box;
            return { value: box };
         }
      }
   };
})();
// Package WCom.Table.CellTrait.Date
WCom.Table.CellTrait.Date = (function() {
   /** @mixin TableCellTrait/Date
       @desc Date cell trait
   */
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            this.appendValue(attr, 'className', 'date');
            result.value = new Date(result.value).toLocaleDateString();
            return result;
         }
      }
   };
})();
// Package WCom.Table.CellTrait.DateTime
WCom.Table.CellTrait.DateTime = (function() {
   /** @mixin TableCellTrait/DateTime
       @desc Date/time cell trait
   */
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            this.appendValue(attr, 'className', 'datetime');
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
// Package WCom.Table.CellTrait.Icon
WCom.Table.CellTrait.Icon = (function() {
   /** @mixin TableCellTrait/Icon
       @desc Icon cell trait
   */
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            return {
               value: this.h.icon({
                  className: 'icon',
                  icons: this.column.table.icons,
                  name: result.value
               })
            };
         }
      }
   };
})();
// Package WCom.Table.CellTrait.Modal
WCom.Table.CellTrait.Modal = (function() {
   /** @mixin TableCellTrait/Modal
       @desc Modal cell trait
   */
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            const href = result.link;
            const url = new URL(href)
            const col = this.column;
            const icons = col.options['modal-icons'] || col.table.icons;
            const title = col.options['title'] || 'Modal Dialog';
            const trigger = col.options['trigger-modal'];
            const constraints = col.options['constraints'];
            if (url.searchParams.get(trigger) != 'true') return result;
            delete result.link;
            const onclick = function(event) {
               event.preventDefault();
               const modal = WCom.Modal.create({
                  callback: function(ok, popup, data) {
                     if (ok && data) console.log(data);
                  }.bind(this),
                  cancelCallback: function() {},
                  dragConstraints: constraints,
                  formClass: 'classic',
                  icons,
                  initValue: null,
                  noButtons: true,
                  title,
                  url: href
               });
               this.column.table.modal = modal;
            }.bind(this);
            const value = this.h.a({ href, onclick }, result.value);
            value.setAttribute('clicklistener', true);
            return { value };
         }
      }
   };
})();
// Package WCom.Table.CellTrait.Numeric
WCom.Table.CellTrait.Numeric = (function() {
   /** @mixin TableCellTrait/Numeric
       @desc Numeric cell trait
   */
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
// Package WCom.Table.CellTrait.Remainder
WCom.Table.CellTrait.Remainder = (function() {
   /** @mixin TableCellTrait/Remainder
       @desc Remainder cell trait
   */
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            this.appendValue(attr, 'className', 'remainder');
            return result;
         }
      }
   };
})();
// Package WCom.Table.CellTrait.Tagable
WCom.Table.CellTrait.Tagable = (function() {
   /** @mixin TableCellTrait/Tagable
       @desc Tagable cell trait
   */
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
// Package WCom.Table.CellTrait.Time
WCom.Table.CellTrait.Time = (function() {
   /** @mixin TableCellTrait/Time
       @desc Time cell trait
   */
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
