// -*- coding: utf-8; -*-
// Package WCom.Table.CellTrait.Bool
WCom.Table.CellTrait.Bool = (function() {
   let bool_colours = [ 'firebrick', 'seagreen'];
   let bool_false = '✗';
   let bool_true = '✓';
   return {
      initialise: function() {
         const options = this.column.options;
         if (options.bool_colours) bool_colours = options.bool_colours;
         if (options.bool_false) bool_false = options.bool_false;
         if (options.bool_true) bool_true = options.bool_true;
      },
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            if (result.value.length == 0) return result;
            this.appendValue(attr, 'className', 'boolean');
            if (!result.value || result.value == 0) {
               this.appendValue(attr, 'style', 'color:' + bool_colours[0]);
               result.value = bool_false;
            }
            else {
               this.appendValue(attr, 'style', 'color:' + bool_colours[1]);
               result.value = bool_true;
            }
            return result;
         }
      }
   };
})();
// Package WCom.Table.CellTrait.Capitalise
WCom.Table.CellTrait.Capitalise = (function() {
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
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            const col = this.column;
            this.appendValue(attr, 'className', 'checkbox');
            if (col.width) this.appendValue(attr, 'style', col.width);
            const handler = function(event) {
               if (col.table.formControl) col.table.formControl.renderAll();
            }.bind(this);
            let name = col.name;
            let box;
            if (col.options['select_one']) {
               const id = name + '.' + this.row.index;
               box = this.h.radio({
                  id: id, name: name, onclick: handler, value: result.value
               });
               col.rowSelector[id] = box;
            }
            else {
               name += '.' + this.row.index;
               box = this.h.checkbox({
                  id: name, name: name, onclick: handler, value: result.value
               });
               col.rowSelector[name] = box;
            }
            return { value: box };
         }
      }
   };
})();
// Package WCom.Table.CellTrait.Date
WCom.Table.CellTrait.Date = (function() {
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
// Package WCom.Table.CellTrait.DateTime
WCom.Table.CellTrait.DateTime = (function() {
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
// Package WCom.Table.CellTrait.Icon
WCom.Table.CellTrait.Icon = (function() {
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
   return {
      around: {
         getValue: function(orig, attr) {
            const result = orig(attr);
            const href = result.link;
            const url = new URL(href)
            const icons = this.column.options['modal-icons'] || '/icons.svg';
            const trigger = this.column.options['trigger-modal'];
            if (url.searchParams.get(trigger) != 'true') return result;
            delete result.link;
            const onclick = function(event) {
               event.preventDefault();
               const modal = WCom.Modal.create({
                  callback: function(ok, popup, data) {
                     if (ok && data) console.log(data);
                  }.bind(this),
                  cancelCallback: function() {},
                  formClass: 'filemanager',
                  icons,
                  initValue: null,
                  noButtons: true,
                  title: 'File Preview',
                  url: href
               });
               this.column.table.modal = modal;
            }.bind(this);
            const anchorAttr = { href: href, onclick: onclick };
            const value = this.h.a(anchorAttr, result.value);
            value.setAttribute('clicklistener', true);
            return { value: value };
         }
      }
   };
})();
// Package WCom.Table.CellTrait.Numeric
WCom.Table.CellTrait.Numeric = (function() {
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
// Package WCom.Table.CellTrait.Tagable
WCom.Table.CellTrait.Tagable = (function() {
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
