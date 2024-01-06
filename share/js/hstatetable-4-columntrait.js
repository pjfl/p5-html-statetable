// -*- coding: utf-8; -*-
HStateTable.ColumnTrait.CheckAll = (function() {
   class CheckAll {
      constructor(column, methods) {
         this.column = column;
         this.handler = function(event) {
            if (!Object.keys(this.column.rowSelector).length) return;
            for (const box of Object.values(this.column.rowSelector)) {
               box.checked = this.column.checkAll.checked;
            }
            this.column.table[this.column.table.formControl.control]();
         }.bind(this);
         methods['render'] = function(orig) { return this.render() }.bind(this);
      }
      render() {
         const attr = {};
         const col = this.column;
         if (col.title) attr.title = col.title;
         if (col.width) attr.style = col.width;
         col.checkAll = this.h.checkbox({
            className: 'check-all', onclick: this.handler
         });
         return this.h.th(
            attr, this.h.span({ className: 'checkall-control' }, col.checkAll)
         );
      }
   }
   Object.assign(CheckAll.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         this.checkAll = new CheckAll(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.ColumnTrait.Filterable
HStateTable.ColumnTrait.Filterable = (function() {
   class Filterable {
      constructor(column, methods, args) {
         args ||= {};
         this.column = column;
         this.dialog;
         this.dialogState = false;
         this.dialogTitle = args['dialogTitle'] || ' ';
         this.label = args['label'] || 'V';
         this.records;
         this.table = column.table;
         this.rs = column.table.resultset;
         this.rs.extendState('filterColumnValues');
         this.rs.nameMap('filterColumnValues', 'filter_column_values');
         this.dialogHandler = function(event) {
            event.preventDefault();
            this.dialogState = !this.dialogState;
            if (this.dialogState) this.render();
            else {
               this.dialog.remove();
               this.rs.redraw();
            }
         }.bind(this);
         methods['render'] = function(orig) {
            const container = orig();
            container.append(this.renderAnchor());
            return container;
         }.bind(this);
      }
      renderAnchor() {
         const attr  = { className: 'filter-label' };
         const isURL = this.label.match(/:/) ? true : false;
         if (!isURL) attr.className = 'filter-label text';
         const label = isURL ? this.h.img({ src: this.label }) : this.label;
         return this.h.a({
            className: 'filter-control',
            onclick: this.dialogHandler,
            title: this.dialogTitle
         }, this.h.span(attr, label));
      }
      async renderValues() {
         const url = this.table.prepareURL({
            filterColumnValues: this.column.name
         });
         const { object } = await this.bitch.sucks(url);
         this.records = object['records'];
         const items = [];
         for (const value of this.records) {
            items.push(this.h.li({
               className: 'filter-value',
               onclick: this.selectHandler(value)
            }, value));
         }
         return this.h.ul({ className: 'filter-values' }, items);
      }
      async render() {
         this.dialog = this.h.div({ className: 'filter-dialog' }, [
            this.h.div({
               className: 'dialog-title', onclick: this.dialogHandler
            }, [
               this.dialogTitle,
               this.h.span({ className: 'dialog-close' }, 'x' )
            ]),
            await this.renderValues()
         ]);
         this.column.header.append(this.dialog);
      }
      selectHandler(value) {
         return function(event) {
            event.preventDefault();
            this.rs.search({
               filterColumn: this.column.name,
               filterValue: value,
               page: 1
            });
            this.dialogHandler(event);
         }.bind(this);
      }
   }
   Object.assign(Filterable.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function(args) {
         this.filter = new Filterable(this, modifiedMethods, args);
      },
      around: modifiedMethods
   };
})();
