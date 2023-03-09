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
         this.row = row;
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
   Object.assign(Cell.prototype, tableUtils.markup); // Apply role
   Object.assign(Cell.prototype, tableUtils.modifiers); // Apply another role
   class Column {
      constructor(table, config) {
         this.table = table;
         this.rs = table.resultset;
         this.cellTraits = config['cell_traits'] || [];
         this.displayed = config['displayed'];
         this.downloadable = config['downloadable'];
         this.filterable = config['filterable'];
         this.header;
         this.label = config['label'];
         this.name = config['name'];
         this.options = config['options'] || {};
         this.rowSelector = {};
         this.sortable = config['sortable'];
         this.sortDesc = this.rs.state('sortDesc');
         this.title = config['title'];
         this.traits = config['traits'] || [];
         this.width = config['width'] ? ('width:' + config['width'] + ';') : '';
         this.sortHandler = function(event) {
            event.preventDefault();
            this.sortDesc = !this.sortDesc;
            this.rs.search(
               { sortColumn: this.name, sortDesc: this.sortDesc }
            ).redraw();
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
   Object.assign(Column.prototype, tableUtils.markup);
   Object.assign(Column.prototype, tableUtils.modifiers);
   class Row {
      constructor(table, result, index) {
         this.cells = [];
         this.columns = table.columns;
         this.index = index;
         this.result = result;
         this.table = table;

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
   Object.assign(Row.prototype, tableUtils.markup);
   Object.assign(Row.prototype, tableUtils.modifiers);
   class PageControl {
      constructor(table) {
         this.className = 'page-control';
         this.enablePaging = table.properties['enable-paging'];
         this.list = this.h.ul();
         this.list.className = this.className;
         this.pagingText = 'Page %current_page of %last_page';
         this.rs = table.resultset;
         this.table = table;
      }
      firstPage() {
         return 1;
      }
      handler(text) {
         return function(event) {
            event.preventDefault();
            let page = this.rs.state('page');
            const lastPage = this.lastPage();
            if (text == 'first') { page = this.firstPage() }
            else if (text == 'prev' && page > 1) { page -= 1 }
            else if (text == 'next' && page < lastPage) { page += 1 }
            else if (text == 'last') { page = lastPage }
            this.rs.search({ page: page }).redraw();
         }.bind(this);
      }
      interpolatePageText() {
         let text = this.pagingText;
         text = text.replace(/\%current_page/, this.rs.state('page'));
         text = text.replace(/\%last_page/, this.lastPage());
         return text;
      }
      lastPage() {
         let pages = this.totalRecords() / this.rs.state('pageSize');
         let lastPage;
         if (pages == Math.floor(pages)) { lastPage = pages }
         else { lastPage = 1 + Math.floor(pages) }
         if (lastPage < 1) lastPage = 1;
         return lastPage;
      }
      render(container) {
         if (!this.enablePaging) return;
         if (!this.table.properties['no-count']) {
            this.renderPageControl(container);
         }
         else { this.renderPageControlNoCount(container) }
      }
      renderPageControl(container) {
         const currentPage = this.rs.state('page');
         const atFirst = !!(currentPage <= this.firstPage());
         const atLast  = !!(currentPage >= this.lastPage());
         const list = this.h.ul({ className: this.className });
         for (const text of ['first', 'prev', 'page', 'next', 'last']) {
            let item;
            if (text == 'page') {
               item = this.h.li(this.interpolatePageText());
            }
            else if (((text == 'first' || text == 'prev') && atFirst)
                     ||((text == 'next' || text == 'last') && atLast)) {
               item = this.h.li({ className: 'disabled' }, text);
            }
            else {
               item = this.h.li({ onclick: this.handler(text) }, text);
            }
            list.append(item);
            list.append(document.createTextNode('\xA0'));
         }
         container.replaceChild(list, this.list);
         this.list = list;
      }
      renderPageControlNoCount(container) {
         const currentPage = this.rs.state('page');
         const atFirst = !!(currentPage <= this.firstPage());
         const atLast  = !!(currentPage >= this.table.rowCount);
         const list = this.h.ul({ className: this.className });
         for (const text of ['first', 'prev', 'page', 'next']) {
            let item;
            if (text == 'page') {
               item = this.h.li('Page\xA0' + currentPage);
            }
            else if (((text == 'first' || text == 'prev') && atFirst)
                     || (text == 'next' && atLast)) {
               item = this.h.li({ className: 'disabled' }, text);
            }
            else {
               item = this.h.li({ onclick: this.handler(text) }, text);
            }
            list.append(item);
            list.append(document.createTextNode('\xA0'));
         }
         container.replaceChild(list, this.list);
         this.list = list;
      }
      totalRecords() {
         return this.table.properties['total-records'];
      }
   }
   Object.assign(PageControl.prototype, tableUtils.markup);
   class PageSizeControl {
      constructor(table) {
         this.className = 'page-size-control';
         this.enablePaging = table.properties['enable-paging'];
         this.list = this.h.ul();
         this.list.className = this.className;
         this.rs = table.resultset;
         this.table = table;
      }
      handler(size) {
         return function(event) {
            event.preventDefault();
            this.rs.search({ pageSize: size }).redraw();
         }.bind(this);
      }
      render(container) {
         if (!this.enablePaging) return;
         const sizes = [10, 20, 50, 100];
         const maxPageSize = this.table.properties['max-page-size'] || 0;
         if (maxPageSize > 100) sizes.push(maxPageSize);
         const attr = { className: this.className };
         const list = this.h.ul(attr, this.h.li('Showing up to\xA0'));
         for (const size of sizes) {
            const attr = {};
            if (size == this.rs.state('pageSize'))
               attr.className = 'selected-page-size'
            const handler = this.handler(size);
            list.append(this.h.li(attr, this.h.a({ onclick: handler }, size)));
            if (size != sizes.slice(-1))
               list.append(document.createTextNode(',\xA0'));
         }
         list.append(this.h.li('\xA0rows'));
         container.replaceChild(list, this.list);
         this.list = list;
      }
   }
   Object.assign(PageSizeControl.prototype, tableUtils.markup);
   class ParameterMap {
      constructor() {
         this._nameMap = {
            page: 'page',
            pageSize: 'page_size',
            sortColumn: 'sort',
            sortDesc: 'desc'
         };
      }
      nameMap(key, value) {
         if (typeof key == 'undefined') return this._nameMap;
         if (typeof value != 'undefined') this._nameMap[key] = value;
         return this._nameMap[key];
      }
   }
   class State {
      constructor(table) {
         this.page = 1;
         this.pageSize = table.properties['page-size'];
         this.sortColumn = table.properties['sort-column'];
         this.sortDesc = table.properties['sort-desc'];
      }
   }
   class Resultset {
      constructor(table) {
         this.dataURL = table.properties['data-url'];
         this.enablePaging = table.properties['enable-paging'];
         this.index = 0;
         this.maxPageSize = table.properties['max-page-size'] || null;
         this.records = [];
         this.table = table;
         this.totalRecords = 0;
         this.parameterMap = new ParameterMap();
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
      nameMap(key, value) {
         return this.parameterMap.nameMap(key, value);
      }
      async next() {
         if (this.index > 0) return this.records[this.index++];
         const response = await this.fetchJSON(this.table.prepareURL());
         this.records = response['records'];
         this.totalRecords = response['total-records'];
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
      async storeJSON(url, args) {
         const body = this.createQueryString({
            data: JSON.stringify(args),
            _verify: this.table.properties['verify-token']
         });
         const headers = new Headers();
         headers.set(
            'Content-Type', 'application/x-www-form-urlencoded; charset=utf-8'
         );
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
   Object.assign(Resultset.prototype, tableUtils.markup);
   class Table {
      constructor(container, config) {
         this.body = this.h.tbody();
         this.columnIndex = {};
         this.columns = [];
         this.container = container;
         this.header = this.h.thead();
         this.name = config['name'];
         this.properties = config['properties'];
         this.roles = config['roles'];
         this.rows = [];
         this.rowTraits = config['row_traits'] || {};
         this.rowCount = 0;
         this.table = this.h.table({ id: this.name });
         this.resultset = new Resultset(this);

         this.table.append(this.header);
         this.table.append(this.body);
         this.applyRoles(true);

         for (const columnConfig of (config['columns'] || [])) {
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

         this.pageControl = new PageControl(this);
         this.bottomRightControl.append(this.pageControl.list);
         this.pageSizeControl = new PageSizeControl(this);
         this.bottomLeftControl.append(this.pageSizeControl.list);

         this.appendContainer(container, this.orderedContent());
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
            const name = config['role_name'] || this.ucfirst(roleName);
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
            const name = config['role_name'] || this.ucfirst(traitName);
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
      render() {
         this.renderTopLeftControl();
         this.renderTopRightControl();
         this.renderTitleControl();
         this.renderHeader();
         this.renderRows();
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
         this.pageSizeControl.render(this.bottomLeftControl);
         return this.pageSizeControl.list;
      }
      renderBottomRightControl() {
         this.pageControl.render(this.bottomRightControl);
         return this.pageControl.list;
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
   Object.assign(Table.prototype, tableUtils.markup);
   Object.assign(Table.prototype, tableUtils.modifiers);
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
