// -*- coding: utf-8; -*-
WCom.Table.ColumnTrait.CheckAll = (function() {
   class CheckAll {
      constructor(column, methods) {
         this.column = column;
         this.handler = function(event) {
            if (!Object.keys(this.column.rowSelector).length) return;
            for (const box of Object.values(this.column.rowSelector)) {
               box.checked = this.column.checkAll.checked;
            }
            // TODO: What did this do?
//            this.column.table[this.column.table.formControl.control]();
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
   Object.assign(CheckAll.prototype, WCom.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         this.checkAll = new CheckAll(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package WCom.Table.ColumnTrait.Filterable
WCom.Table.ColumnTrait.Filterable = (function() {
   class Filterable {
      constructor(column, methods, args) {
         args ||= {};
         this.column = column;
         this.dialog;
         this.dialogState = false;
         this.dialogTitle = args['dialogTitle'] || ' ';
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
      _createFilterIcon(labelAttr) {
         const icons = this.table.icons;
         if (!icons) {
            labelAttr.className = 'filter-label text';
            return '∇'
         }
         const attr = { className: 'filter-icon', icons, name: 'filter' };
         return this.h.icon(attr);
      }
      renderAnchor() {
         const attr  = { className: 'filter-label' };
         return this.h.a({
            className: 'filter-control',
            onclick: this.dialogHandler,
            title: this.dialogTitle
         }, this.h.span(attr, this._createFilterIcon(attr)));
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
            }, [ this.dialogTitle, this._createCloseIcon() ]),
            await this.renderValues()
         ]);
         this.column.header.append(this.dialog);
      }
      _createCloseIcon() {
         const icons = this.table.icons;
         if (!icons)
            return this.h.span({ className: 'dialog-close text' }, 'X');
         const attr = { className: 'close-icon', icons, name: 'close' };
         return this.h.span({ className: 'dialog-close' }, this.h.icon(attr));
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
   Object.assign(Filterable.prototype, WCom.Util.Bitch);
   Object.assign(Filterable.prototype, WCom.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function(args) {
         this.filter = new Filterable(this, modifiedMethods, args);
      },
      around: modifiedMethods
   };
})();
