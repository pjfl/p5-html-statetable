// -*- coding: utf-8; -*-
// Package HStateTable.ColumnTrait.Filterable
HStateTable.ColumnTrait.Filterable = (function() {
   class Filterable {
      constructor(column, methods) {
         this.column = column;
         this.dialog;
         this.dialogState = false;
         this.records;
         this.rs = column.table.resultset;
         this.table = column.table;
         this.dialogHandler = function(event) {
            event.preventDefault();
            this.dialogState = !this.dialogState;
            if (this.dialogState) this.render();
            else {
               this.dialog.remove();
               this.rs.reset();
               this.table.redraw();
            }
         }.bind(this);
         const params = this.rs.parameterMap;
         params.nameMap('filterColumnValues', 'filter_column_values');
         methods['render'] = function(orig) {
            const container = orig();
            container.append(this.h.a(
               { className: 'filter-control', onclick: this.dialogHandler,
                 title: 'Filter' }, '\xA0⛢\xA0'
            ));
            return container;
         }.bind(this);
      }
      async renderValues() {
         this.rs.state('filterColumnValues', this.column.name);
         const url = this.rs.prepareURL();
         this.rs.state('filterColumnValues', '');
         const response = await this.rs.fetchJSON(url);
         this.records = response['records'];
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
            this.h.div(
               { className: 'dialog-title', onclick: this.dialogHandler },
               this.h.span({ className: 'dialog-close' }, 'x' )
            ),
            await this.renderValues()
         ]);
         this.table.table.append(this.dialog);
      }
      selectHandler(value) {
         return function(event) {
            event.preventDefault();
            this.rs.search({
               filterColumn: this.column.name, filterValue: value
            });
            this.dialogHandler(event);
         }.bind(this);
      }
   }
   Object.assign(Filterable.prototype, HStateTable.Util.markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         this.filter = new Filterable(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
