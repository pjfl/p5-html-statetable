// -*- coding: utf-8; -*-
// Package HStateTable.Renderer
if (!HStateTable.CellTrait) HStateTable.CellTrait = {};
if (!HStateTable.ColumnTrait) HStateTable.ColumnTrait = {};
if (!HStateTable.RowTrait) HStateTable.RowTrait = {};
if (!HStateTable.Role) HStateTable.Role = {};
HStateTable.Renderer = (function() {
   const dsName       = 'tableConfig';
   const triggerClass = 'state-table';
   const cellTraits   = HStateTable.CellTrait;
   const columnTraits = HStateTable.ColumnTrait;
   const rowTraits    = HStateTable.RowTrait;
   const tableRoles   = HStateTable.Role;
   const tableUtils   = HStateTable.Util;
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
         const content = this.getValue(attr);
         const append = content.append;
         if (!content.link) return this.h.td(attr, [content.value, append]);
         const link = this.h.a({ href: content.link }, content.value);
         return this.h.td(attr, [link, append]);
      }
   };
   Object.assign(Cell.prototype, tableUtils.Markup); // Apply role
   Object.assign(Cell.prototype, tableUtils.Modifiers); // Apply another role
   class Column {
      constructor(table, config) {
         this.table        = table;
         this.rs           = table.resultset;
         this.cellTraits   = config['cell_traits'] || [];
         this.displayed    = config['displayed'];
         this.downloadable = config['downloadable'];
         this.filterable   = config['filterable'];
         this.label        = config['label'];
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
         this.applyTraits(cell, cellTraits, this.cellTraits);
         return cell;
      }
      render() {
         this.rowSelector = {};
         const attr = {};
         let content = [this.label || this.ucfirst(this.name)];
         if (this.title) attr.title = this.title;
         if (this.width) attr.style = this.width;
         if (this.sortable) {
            if (this.rs.state('sortColumn') == this.name) {
               attr.className = 'active-sort-column';
            }
            content = [this.h.a({ onclick: this.sortHandler }, content[0])];
         }
         this.header = this.h.th(attr, content);
         return this.header;
      }
   };
   Object.assign(Column.prototype, tableUtils.Markup);
   Object.assign(Column.prototype, tableUtils.Modifiers);
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
   Object.assign(Row.prototype, tableUtils.Markup);
   Object.assign(Row.prototype, tableUtils.Modifiers);
   class State {
      constructor(table) {
         this.page       = 1;
         this.pageSize   = table.properties['page-size'];
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
         this.index        = 0;
         this.records      = [];
         this.rowCount     = 0;
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
      async fetchBlob(url) {
         const response = await fetch(url);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         const headers = response.headers;
         const filename
               = headers.get('content-disposition').split('filename=')[1];
         const blob = await response.blob();
         return { blob: blob, filename: filename };
      }
      async fetchJSON(url) {
         const headers = new Headers();
         headers.set('X-Requested-With', 'XMLHttpRequest');
         const options = { headers: headers, method: 'GET' };
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         return await response.json();
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
         const response = await this.fetchJSON(this.table.prepareURL());
         this.records = response['records'];
         this.rowCount = parseInt(response['row-count']);
         return this.records[this.index++];
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
      async storeJSON(url, args) {
         const body = JSON.stringify({
            data: args, _verify: this.table.properties['verify-token']
         });
         const headers = new Headers();
         headers.set('Content-Type', 'application/json');
         headers.set('X-Requested-With', 'XMLHttpRequest');
         const options = {
            body: body, cache: 'no-store', credentials: 'same-origin',
            headers: headers, method: 'POST',
         };
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         return await response.json();
      }
   };
   class Table {
      constructor(container, config) {
         this.container   = container;
         this.columnConf  = config['columns'] || [];
         this.name        = config['name'];
         this.properties  = config['properties'];
         this.roles       = config['roles'];
         this.rowTraits   = config['row-traits'] || {};
         this.body        = this.h.tbody();
         this.columnIndex = {};
         this.columns     = [];
         this.header      = this.h.thead();
         this.rows        = [];
         this.rowCount    = 0;
         this.table       = this.h.table({ id: this.name });
         this.resultset   = new Resultset(this);

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

         this.topControl = this.h.div({ className: 'top-control' });
         this.topLeftControl = this.h.div({ className: 'top-left-control' });
         this.topControl.append(this.topLeftControl);
         this.topRightControl = this.h.div({ className: 'top-right-control' });
         this.topControl.append(this.topRightControl);

         this.bottomControl = this.h.div({ className: 'bottom-control' });
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
            this.applyTraits(this, tableRoles, [name]);
         }
      }
      createColumn(config) {
         return new Column(this, config);
      }
      async nextResult() {
         return await this.resultset.next();
      }
      async nextRow(index) {
         const result = await this.nextResult()
         if (!result) return undefined;
         const row = new Row(this, result, index);
         for (const [traitName, config] of Object.entries(this.rowTraits)) {
            const name = config['role-name'] || this.ucfirst(traitName);
            this.applyTraits(row, rowTraits, [name]);
         }
         return row;
      }
      orderedContent() {
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
         if (rs.enablePaging) {
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
      renderHeader() {
         const row = this.h.tr();
         for (const column of this.columns) {
            if (column.displayed) row.append(column.render());
         }
         const thead = this.h.thead(row);
         this.table.replaceChild(thead, this.header);
         this.header = thead;
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
      renderNoData() {
         const message = this.properties['no-data-message'];
         const cell = this.h.td({ colSpan: this.columns.length }, message);
         return this.h.tr(cell);
      }
      async renderRows() {
         this.rows = [];
         this.rowCount = 0;
         let index = 0;
         let row;
         while (row = await this.nextRow(index++)) { this.rows.push(row) }
         this.rowCount = this.rows.length;
         const tbody = this.h.tbody();
         if (this.rowCount) {
            let className = 'odd';
            for (row of this.rows) {
               const rendered = row.render({ className: className });
               className = (className == 'odd') ? 'even' : 'odd';
               tbody.append(rendered);
            }
         }
         else { tbody.append(this.renderNoData()) }
         this.table.replaceChild(tbody, this.body);
         this.body = tbody;
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
   };
   Object.assign(Table.prototype, tableUtils.Markup);
   Object.assign(Table.prototype, tableUtils.Modifiers);
   class Manager {
      constructor() {
         this.tables = {};
      }
      createTables() {
         for (const el of document.getElementsByClassName(triggerClass)) {
            const table = new Table(el, JSON.parse(el.dataset[dsName]));
            this.tables[table.name] = table;
            table.render();
         }
      }
      onReady(callback) {
         if (document.readyState != 'loading') callback();
         else if (document.addEventListener)
            document.addEventListener('DOMContentLoaded', callback);
         else document.attachEvent('onreadystatechange', function() {
            if (document.readyState == 'complete') callback();
         });
      }
   }
   const manager = new Manager();
   manager.onReady(function() { manager.createTables(); });
})();
