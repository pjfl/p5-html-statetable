// -*- coding: utf-8; -*-
// Package HStateTable.Renderer
if (!HStateTable.CellTrait) HStateTable.CellTrait = {};
if (!HStateTable.ColumnTrait) HStateTable.ColumnTrait = {};
if (!HStateTable.Role) HStateTable.Role = {};
HStateTable.Renderer = (function() {
   const dsName       = 'tableConfig';
   const triggerClass = 'state-table';
   const cellTraits   = HStateTable.CellTrait;
   const columnTraits = HStateTable.ColumnTrait;
   const tableRoles   = HStateTable.Role;
   const tableUtils   = HStateTable.Util;
   class Cell {
      constructor(column, row) {
         this.column = column;
         this.row = row;
      }
      getValue() {
         const value = this.row.result[this.column.name];
         if (typeof value == 'object') return value;
         return { value: value };
      }
      render() {
         const attr = {};
         const content = this.getValue();
         if (content.wrapperClass) { attr.className = content.wrapperClass }
         if (!content.link) return this.h.td(attr, content.value);
         const link = this.h.a({ href: content.link }, content.value);
         return this.h.td(attr, link);
      }
   };
   Object.assign(Cell.prototype, tableUtils.markup); // Apply role
   Object.assign(Cell.prototype, tableUtils.modifiers); // Apply another role
   class Column {
      constructor(table, config) {
         this.cellTraits = config['cell_traits'] || [];
         this.displayed = config['displayed'];
         this.label = config['label'];
         this.name = config['name'];
         this.options = config['options'] || {};
         this.sortable = config['sortable'];
         this.sortDesc = table.state('sortDesc');
         this.table = table;
         this.traits = config['traits'] || [];
      }
      clickHandler() {
         return function(event) {
            event.preventDefault();
            this.sortDesc = !this.sortDesc;
            this.table.resultset.search({
               sortColumn: this.name, sortDesc: this.sortDesc
            });
            this.table.redraw();
         }.bind(this);
      }
      createCell(row) {
         const cell = new Cell(this, row);
         this.applyTraits(cell, cellTraits, this.cellTraits);
         return cell;
      }
      render() {
         let content = this.label || this.name;
         if (!this.sortable) return this.h.th(content);
         if (this.table.state('sortColumn') == this.name) {
            content += '\xA0' + (this.sortDesc ? '▾' : '▴');
         }
         const handler = this.clickHandler();
         return this.h.th({}, this.h.a({ onclick: handler }, content));
      }
   };
   Object.assign(Column.prototype, tableUtils.markup);
   Object.assign(Column.prototype, tableUtils.modifiers);
   class PageControl {
      constructor(table) {
         this.className = 'page-control';
         this.enablePaging = table.properties['enable-paging'];
         this.list = this.h.ul();
         this.list.className = this.className;
         this.pagingText = 'Page %current_page of %last_page';
         this.table = table;
      }
      clickHandler(text) {
         return function(event) {
            event.preventDefault();
            let page = this.table.state('page');
            const lastPage = this.lastPage();
            if (text == 'first') { page = this.firstPage() }
            else if (text == 'prev' && page > 1) { page -= 1 }
            else if (text == 'next' && page < lastPage) { page += 1 }
            else if (text == 'last') { page = lastPage }
            this.table.resultset.search({ page: page });
            this.table.redraw();
         }.bind(this);
      }
      firstPage() {
         return 1;
      }
      interpolatePageText() {
         let text = this.pagingText;
         text = text.replace(/\%current_page/, this.table.state('page'));
         text = text.replace(/\%last_page/, this.lastPage());
         return text;
      }
      lastPage() {
         let pages = this.totalRecords() / this.table.state('pageSize');
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
         const currentPage = this.table.state('page');
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
               item = this.h.li({ onclick: this.clickHandler(text) }, text);
            }
            list.append(item);
            list.append(document.createTextNode('\xA0'));
         }
         container.replaceChild(list, this.list);
         this.list = list;
      }
      renderPageControlNoCount(container) {
         const currentPage = this.table.state('page');
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
               item = this.h.li({ onclick: this.clickHandler(text) }, text);
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
         this.table = table;
      }
      clickHandler(size) {
         return function(event) {
            event.preventDefault();
            this.table.resultset.search({ pageSize: size });
            this.table.redraw();
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
            if (size == this.table.state('pageSize'))
               attr.className = 'selected-page-size'
            const handler = this.clickHandler(size);
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
            filterColumn: 'filter_column',
            filterValue: 'filter_value',
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
   class Resultset {
      constructor(table) {
         this.dataURL = table.properties['data-url'];
         this.enablePaging = table.properties['enable-paging'];
         this.index = 0;
         this.maxPageSize = table.properties['max-page-size'] || null;
         this.records = [];
         this.table = table;
         this.totalRecords = 0;
      }
      async fetchJSON(url) {
         // TODO: Set request application/json and loose this
         const headers = new Headers();
         headers.set('X-Requested-With', 'XMLHttpRequest');
         const options = { headers: headers, method: 'GET' };
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         return await response.json();
      }
      async next() {
         if (this.index > 0) return this.records[this.index++];
         const response = await this.fetchJSON(this.prepareURL());
         this.records = response['records'];
         this.totalRecords = response['total-records'];
         return this.records[this.index++];
      }
      prepareURL() {
         const url = new URL(this.dataURL);
         const state = this.table.state.bind(this.table);
         const nameMap = this.table.parameterMap.nameMap.bind(
            this.table.parameterMap
         );
         const download = state('download');
         if (download) url.searchParams.set(nameMap('download'), download);
         else url.searchParams.delete(nameMap('download'));
         const filterColumn = state('filterColumn');
         const filterValue = state('filterValue');
         if (filterColumn && filterValue) {
            url.searchParams.set(nameMap('filterColumn'), filterColumn);
            url.searchParams.set(nameMap('filterValue'), filterValue);
         }
         else {
            url.searchParams.delete(nameMap('filterColumn'));
            url.searchParams.delete(nameMap('filterValue'));
         }
         if (this.enablePaging && !download) {
            url.searchParams.set(nameMap('page'), state('page'));
            const pageSize = this.maxPageSize
                  && state('pageSize') > this.maxPageSize
                  ? this.maxPageSize : state('pageSize');
            url.searchParams.set(nameMap('pageSize'), pageSize);
         }
         else {
            url.searchParams.delete(nameMap('page'));
            url.searchParams.delete(nameMap('pageSize'));
         }
         const searchColumn = state('searchColumn');
         const searchValue = state('searchValue');
         if (searchColumn && searchValue) {
            url.searchParams.set(nameMap('searchColumn'), searchColumn);
            url.searchParams.set(nameMap('searchValue'), searchValue);
         }
         else {
            url.searchParams.delete(nameMap('searchColumn'));
            url.searchParams.delete(nameMap('searchValue'));
         }
         const sortColumn = state('sortColumn');
         if (sortColumn) url.searchParams.set(nameMap('sortColumn'), sortColumn);
         else url.searchParams.delete(nameMap('sortColumn'));
         const sortDesc = state('sortDesc');
         if (sortColumn && sortDesc)
            url.searchParams.set(nameMap('sortDesc'), sortDesc);
         else url.searchParams.delete(nameMap('sortDesc'));
         return url;
      }
      reset() {
         this.index = 0;
         return this;
      }
      search(options) {
         const state  = this.table.state.bind(this.table);
         for (const [k, v] of Object.entries(options)) { state(k, v) }
         return this.reset();
      }
   };
   class Row {
      constructor(table, result) {
         this.cells = [];
         this.columns = table.columns;
         this.result = result;
         this.table = table;

         for (const column of this.columns) {
            this.cells.push(column.createCell(this));
         }
      }
      render() {
         const row = this.h.tr();
         for (const cell of this.cells) { row.append(cell.render()) }
         return row;
      }
   };
   Object.assign(Row.prototype, tableUtils.markup);
   class State {
      constructor(table) {
         this.download;
         this.filterColumn;
         this.filterValue;
         this.page = 1;
         this.pageSize = 20;
         this.searchColumn;
         this.searchValue;
         this.sortColumn;
         this.sortDesc = false;
         const url = new URL(table.resultset.dataURL);
         for (const [k, v] of Object.entries(table.parameterMap.nameMap())) {
            const value = url.searchParams.get(v);
            if (value) this[k] = value;
         }
      }
   }
   class Table {
      constructor(container, config) {
         this.body = this.h.tbody();
         this.columns = [];
         this.container = container;
         this.header = this.h.thead();
         this.name = config['name'];
         this.properties = config['properties'];
         this.roles = config['roles'];
         this.rows = [];
         this.rowCount = 0;
         this.table = this.h.table({ id: this.name });
         this.parameterMap = new ParameterMap();
         this.resultset = new Resultset(this);
         this._state = new State(this);

         for (const column of (config['columns'] || [])) {
            this.columns.push(new Column(this, column));
         }

         this.applyRoles();
         this.table.append(this.header);
         this.table.append(this.body);

         this.titleControl = this.h.div({ className: 'title-control' });
         this.container.append(this.titleControl);
         this.topLeftControl = this.h.div({ className: 'top-left-control' });
         this.container.append(this.topLeftControl);
         this.topRightControl = this.h.div({ className: 'top-right-control' });
         this.container.append(this.topRightControl);

         this.container.append(this.table);

         this.bottomLeftControl
            = this.h.div({ className: 'bottom-left-control' });
         this.container.append(this.bottomLeftControl);
         this.bottomRightControl
            = this.h.div({ className: 'bottom-right-control' });
         this.container.append(this.bottomRightControl);
         this.creditControl = this.h.div({ className: 'credit-control'});
         this.container.append(this.creditControl);

         this.pageControl = new PageControl(this);
         this.bottomRightControl.append(this.pageControl.list);
         this.pageSizeControl = new PageSizeControl(this);
         this.bottomLeftControl.append(this.pageSizeControl.list);
      }
      applyRoles() {
         for (const [roleName, config] of Object.entries(this.roles)) {
            const name = config['role_name'] || roleName;
            this.applyTraits(this, tableRoles, [name]);
         }
      }
      async nextResult() {
         return await this.resultset.next();
      }
      async nextRow() {
         const result = await this.nextResult()
         return result ? new Row(this, result) : undefined;
      }
      redraw() {
         this.render();
      }
      render() {
         this.renderTitleControl();
         this.renderTopLeftControl();
         this.renderTopRightControl();
         this.renderHeader();
         this.renderRows();
         this.renderBottomLeftControl();
         this.renderBottomRightControl();
         this.renderCreditControl();
      }
      renderHeader() {
         const row = this.h.tr();
         for (const column of this.columns) { row.append(column.render()) }
         const thead = this.h.thead({}, row);
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
         const cell = this.h.td({ colspan: this.columns.length }, message);
         return this.h.tr({}, cell);
      }
      async renderRows() {
         this.rows = [];
         this.rowCount = 0;
         let row;
         while (row = await this.nextRow()) { this.rows.push(row) }
         this.rowCount = this.rows.length;
         const tbody = this.h.tbody();
         if (this.rowCount) {
            let className = 'odd';
            for (row of this.rows) {
               const rendered = row.render();
               rendered.className = className;
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
      state(key, value) {
         if (typeof value !== 'undefined') {
            this._state[key] = value;
            if (key == 'pageSize') this._state['page'] = 1;
         }
         return this._state[key];
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
