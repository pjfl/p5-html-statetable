// -*- coding: utf-8; -*-
// Package HStateTable.Renderer
if (!HStateTable.CellTrait) HStateTable.CellTrait = {};
if (!HStateTable.ColumnTrait) HStateTable.ColumnTrait = {};
if (!HStateTable.RowTrait) HStateTable.RowTrait = {};
if (!HStateTable.Role) HStateTable.Role = {};
HStateTable.Renderer = (function() {
   const dsName       = 'tableConfig';
   const triggerClass = 'state-table';
   const CellTraits   = HStateTable.CellTrait;
   const ColumnTraits = HStateTable.ColumnTrait;
   const RowTraits    = HStateTable.RowTrait;
   const TableRoles   = HStateTable.Role;
   const TableUtils   = HStateTable.Util;
   class Cell {
      constructor(column, row) {
         this.column = column;
         this.row    = row;
      }
      getValue(attr) {
         const value = this.row.result[this.column.name];
         if (typeof value == 'object') return value;
         return { value: value };
      }
      render() {
         const attr = {};
         const { append, link, value } = this.getValue(attr);
         let cell;
         if (this.isHTMLOfClass(value, triggerClass)) {
            cell = this.h.td(attr);
            cell.innerHTML = value;
            HStateTable.Renderer.manager.scan(cell);
         }
         else {
            let content;
            if (!link) content = [value, append];
            else content = [this.h.a({ href: link }, value), append];
            cell = this.h.td(attr, content);
         }
         cell.setAttribute('data-cell', this.column.name);
         return cell;
      }
   };
   Object.assign(Cell.prototype, TableUtils.Markup); // Apply role
   Object.assign(Cell.prototype, TableUtils.Modifiers); // Apply another role
   class Column {
      constructor(table, config) {
         this.table        = table;
         this.rs           = table.resultset;
         this.cellTraits   = config['cell_traits'] || [];
         this.displayed    = config['displayed'];
         this.downloadable = config['downloadable'];
         this.filterable   = config['filterable'];
         this.label        = config['label'];
         this.minWidth     = config['min_width']
            ? ('min-width:' + config['min_width'] + ';') : '';
         this.name         = config['name'];
         this.options      = config['options'] || {};
         this.sortable     = config['sortable'];
         this.title        = config['title'];
         this.traits       = config['traits'] || [];
         this.width        = config['width']
            ? ('width:' + config['width'] + ';') : '';
         this.header;
         this.rowSelector  = {};
         this.sortDesc     = this.rs.state('sortDesc');
         this.sortHandler  = function(event) {
            event.preventDefault();
            this.sortDesc = !this.sortDesc;
            this.rs.search({
               sortColumn: this.name, sortDesc: this.sortDesc
            }).redraw();
         }.bind(this);
      }
      createCell(row) {
         const cell = new Cell(this, row);
         this.applyTraits(cell, CellTraits, this.cellTraits);
         const result = row.result[this.name];
         if (result.cellTraits && !this.options['notraits']) {
            this.applyTraits(cell, CellTraits, result.cellTraits);
         }
         return cell;
      }
      render() {
         this.rowSelector = {};
         const attr = { style: '' };
         let content = [this.label || this.ucfirst(this.name)];
         if (this.title) attr.title = this.title;
         if (this.minWidth) attr.style += this.minWidth;
         if (this.width) attr.style += this.width;
         if (this.sortable) {
            if (this.rs.state('sortColumn') == this.name) {
               attr.className = 'active-sort-column';
            }
            content = [this.h.a({ onclick: this.sortHandler }, content[0])];
         }
         else if (content[0].match(/[^ ]/)) {
            content = [this.h.span({ className: 'column-header' }, content[0])];
         }
         this.header = this.h.th(attr, content);
         return this.header;
      }
   };
   Object.assign(Column.prototype, TableUtils.Markup);
   Object.assign(Column.prototype, TableUtils.Modifiers);
   class Row {
      constructor(table, result, index) {
         this.table   = table;
         this.result  = result;
         this.index   = index;
         this.cells   = [];
         this.columns = table.columns;

         for (const column of this.columns) {
            this.cells.push(column.createCell(this));
         }
      }
      render(attr) {
         attr ||= {};
         const row = this.h.tr(attr);
         for (const cell of this.cells) {
            if (cell.column.displayed) row.append(cell.render());
         }
         return row;
      }
   };
   Object.assign(Row.prototype, TableUtils.Markup);
   Object.assign(Row.prototype, TableUtils.Modifiers);
   class State {
      constructor(table) {
         this.page       = 1;
         this.pageSize   = table.properties['page-size'];
         this.prevPage   = 0;
         this.sortColumn = table.properties['sort-column'];
         this.sortDesc   = table.properties['sort-desc'];
      }
   }
   class Resultset {
      constructor(table) {
         this.table        = table;
         this.dataURL      = table.properties['data-url'];
         this.enablePaging = table.properties['enable-paging'];
         this.maxPageSize  = table.properties['max-page-size'] || null;
         this.rowCount     = table.properties['row-count'];
         this.token        = table.properties['verify-token'];
         this.index        = 0;
         this.records      = [];
         this.parameterMap = {
            page: 'page',
            pageSize: 'page_size',
            sortColumn: 'sort',
            sortDesc: 'desc'
         };
         this._state = new State(table);
      }
      extendState(key, value) {
         this._state[key] = value;
      }
      getState(attrs) {
         const state = {};
         for (const attr of attrs) { state[attr] = this.state(attr) || '' }
         return state;
      }
      nameMap(key, value) {
         if (typeof key == 'undefined') return this.parameterMap;
         if (typeof value != 'undefined') this.parameterMap[key] = value;
         return this.parameterMap[key];
      }
      async next() {
         if (this.index > 0) return this.records[this.index++];
         const { object } = await this.bitch.sucks(this.table.prepareURL());
         if (object && object['records']) {
            this.records = object['records'];
            this.rowCount = parseInt(object['row-count']);
            return this.records[this.index++];
         }
         this.records = [];
         this.rowCount = 0;
         return this.records[0];
      }
      redraw() {
         this.reset();
         this.table.redraw();
         return this;
      }
      reset() {
         this.index = 0;
         return this;
      }
      search(options) {
         for (const [k, v] of Object.entries(options)) { this.state(k, v) }
         return this.reset();
      }
      state(key, value) {
         if (typeof value !== 'undefined') {
            if (key == 'page' || key == 'pageSize')
               this._state['prevPage'] = this._state['page'];
            this._state[key] = value;
            if (key == 'pageSize') this._state['page'] = 1;
         }
         return this._state[key];
      }
      stateChanged(previousState) {
         for (const [key, previous] of Object.entries(previousState)) {
            const current = this.state(key) || '';
            if (previous != current) return true;
         }
         return false;
      }
   };
   Object.assign(Resultset.prototype, TableUtils.Markup);
   class Table {
      constructor(container, config) {
         this.container  = container;
         this.columnConf = config['columns'] || [];
         this.name       = config['name'];
         this.properties = config['properties'];
         this.roles      = config['roles'];
         this.rowTraits  = config['row-traits'] || {};

         this.body          = this.h.tbody();
         this.bottomContent = false;
         this.caption       = this.properties['caption'];
         this.columnIndex   = {};
         this.columns       = [];
         this.header        = this.h.thead();
         this.modal         = {};
         this.pageManager   = eval(this.properties['page-manager'] || '');
         this.renderStyle   = this.properties['render-style'];
         this.rows          = [];
         this.rowCount      = 0;
         this.resultset     = new Resultset(this);
         this.titleLocation = this.properties['title-location'] || 'inner';
         this.topContent    = false;

         const attr = { id: this.name, style: '' };
         if (this.properties['max-width']) this.appendValue(
            attr, 'style', 'max-width:' + this.properties['max-width']
         );
         this.table = this.h.table(attr);
         if (this.caption.length)
            this.table.append(this.h.caption(this.caption));
         this.table.append(this.header);
         this.table.append(this.body);
         this.applyRoles(true);

         for (const columnConfig of this.columnConf) {
            const column = this.createColumn(columnConfig);
            this.columnIndex[column.name] = column;
            this.columns.push(column);
         }

         this.applyRoles(false);
         this.titleControl = this.h.div({ className: 'title-control' });

         let className = 'top-control';
         if (this.topContent) className += ' visible';
         this.topControl = this.h.div({ className: className });
         this.topLeftControl = this.h.div({ className: 'top-left-control' });
         this.topControl.append(this.topLeftControl);
         this.topRightControl = this.h.div({ className: 'top-right-control' });
         this.topControl.append(this.topRightControl);

         className = 'bottom-control';
         if (this.bottomContent) className += ' visible';
         this.bottomControl = this.h.div({ className: className });
         this.bottomLeftControl
            = this.h.div({ className: 'bottom-left-control' });
         this.bottomControl.append(this.bottomLeftControl);
         this.bottomRightControl
            = this.h.div({ className: 'bottom-right-control' });
         this.bottomControl.append(this.bottomRightControl);

         this.creditControl = this.h.div({ className: 'credit-control'});

         this.tableContainer = this.h.div({
            className: 'table-container'
         }, this.orderedContent());

         this.appendContainer(container, [this.tableContainer]);
      }
      appendContainer(container, content) {
         for (const el of content) { container.append(el); }
      }
      applyRoles(before) {
         const roleIndex = [];
         for (const roleName of Object.keys(this.roles)) {
            roleIndex[this.roles[roleName]['role-index']] = roleName;
         }
         for (const roleName of roleIndex) {
            if (!roleName) return;
            const config = this.roles[roleName];
            const apply = config['apply'] ? config['apply'] : {};
            if (before && !apply['before']) continue;
            if (!before && apply['before']) continue;
            const name = config['role-name'] || this.ucfirst(roleName);
            this.applyTraits(this, TableRoles, [name]);
         }
      }
      createColumn(config) {
         return new Column(this, config);
      }
      async nextResult() {
         return await this.resultset.next();
      }
      async nextRow(index) {
         const result = await this.nextResult();
         if (!result) return undefined;
         const row = new Row(this, result, index);
         for (const [traitName, config] of Object.entries(this.rowTraits)) {
            const name = config['role-name'] || this.ucfirst(traitName);
            this.applyTraits(row, RowTraits, [name]);
         }
         return row;
      }
      orderedContent() {
         if (this.titleLocation == 'outer') {
            return [
               this.titleControl, this.topControl,
               this.table,
               this.bottomControl, this.creditControl
            ];
         }
         return [
            this.topControl, this.titleControl,
            this.table,
            this.creditControl, this.bottomControl
         ];
      }
      prepareURL(args) {
         args ||= {};
         const rs = this.resultset;
         const url = new URL(rs.dataURL);
         const params = url.searchParams;
         if (rs.enablePaging && !args.disablePaging) {
            params.set(rs.nameMap('page'), rs.state('page'));
            const max = rs.maxPageSize;
            const pageSize = max && rs.state('pageSize') > max
                  ? max : rs.state('pageSize');
            params.set(rs.nameMap('pageSize'), pageSize);
         }
         else {
            params.delete(rs.nameMap('page'));
            params.delete(rs.nameMap('pageSize'));
         }
         const sortColumn = rs.state('sortColumn');
         if (sortColumn) params.set(rs.nameMap('sortColumn'), sortColumn);
         else params.delete(rs.nameMap('sortColumn'));
         const sortDesc = rs.state('sortDesc');
         if (sortColumn && sortDesc)
            params.set(rs.nameMap('sortDesc'), sortDesc);
         else params.delete(rs.nameMap('sortDesc'));
         return url;
      }
      async readRows() {
         this.rows = [];
         let index = 0;
         let row;
         while (row = await this.nextRow(index++)) { this.rows.push(row) }
      }
      redraw() {
         this.render();
      }
      async render() {
         this.renderHeader();
         await this.renderRows();
         this.renderTopLeftControl();
         this.renderTopRightControl();
         this.renderTitleControl();
         this.renderCreditControl();
         this.renderBottomLeftControl();
         this.renderBottomRightControl();
      }
      renderBody() {
         const newBody = this.h.tbody();
         let className = 'odd';
         for (const row of this.rows) {
            const rendered = this.renderRow(newBody, row, className);
            rendered.classList.add('visible');
            className = (className == 'odd') ? 'even' : 'odd';
         }
         this.table.replaceChild(newBody, this.body);
         this.body = newBody;
      }
      renderBottomLeftControl() {
         return this.bottomLeftControl;
      }
      renderBottomRightControl() {
         return this.bottomRightControl;
      }
      renderCreditControl() {
         return this.creditControl;
      }
      renderHeader() {
         const row = this.h.tr();
         for (const column of this.columns) {
            if (column.displayed) row.append(column.render());
         }
         const thead = this.h.thead(row);
         this.table.replaceChild(thead, this.header);
         this.header = thead;
      }
      renderNoData() {
         const message = this.properties['no-data-message'];
         const cell    = this.h.td({ colSpan: this.columns.length }, message);
         const tbody   = this.h.tbody(this.h.tr(cell));
         this.table.replaceChild(tbody, this.body);
         this.body = tbody;
      }
      renderRow(container, row, className) {
         const rendered = row.render({ className: className });
         container.append(rendered);
         return rendered;
      }
      async renderRows() {
         await this.readRows();
         if (!this.rows.length) return this.renderNoData();
         this.renderBody();
         this.rowCount = this.rows.length;
         if (this.pageManager) this.pageManager.onContentLoad();
      }
      renderTitleControl() {
         return this.titleControl;
      }
      renderTopLeftControl() {
         return this.topLeftControl;
      }
      renderTopRightControl() {
         return this.topRightControl;
      }
      setControlState(control) {
         if (control.match(/Bottom/)) this.bottomContent = true;
         if (control.match(/Top/)) this.topContent = true;
      }
   };
   Object.assign(Table.prototype, TableUtils.Markup);
   Object.assign(Table.prototype, TableUtils.Modifiers);
   class Manager {
      constructor() {
         this._isConstructing = true;
         this.tables = {}; // TODO: Figure out if we can let this go
         this.onReady(function() { this.createTables() }.bind(this));
      }
      async createTables() {
         await this.scan(document);
         this._isConstructing = false;
      }
      isConstructing() {
         return new Promise(function(resolve) {
            setTimeout(() => {
               if (!this._isConstructing) resolve(false);
            }, 250);
         }.bind(this));
      }
      onReady(callback) {
         if (document.readyState != 'loading') callback();
         else if (document.addEventListener)
            document.addEventListener('DOMContentLoaded', callback);
         else document.attachEvent('onreadystatechange', function() {
            if (document.readyState == 'complete') callback();
         });
      }
      async scan(content) {
         const promises = [];
         for (const el of content.getElementsByClassName(triggerClass)) {
            const table = new Table(el, JSON.parse(el.dataset[dsName]));
            this.tables[table.name] = table;
            promises.push(table.render());
         }
         await Promise.all(promises);
         for (const name in this.tables) this.tables[name].animateButtons();
      }
   }
   return {
      manager: new Manager()
   };
})();
