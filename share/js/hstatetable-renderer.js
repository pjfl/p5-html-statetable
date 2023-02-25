// -*- coding: utf-8; -*-
// Package HStateTable.Renderer
if (!window.HStateTable) window.HStateTable = {};
if (!HStateTable.CellTrait) HStateTable.CellTrait = {};
if (!HStateTable.ColumnTrait) HStateTable.ColumnTrait = {};
if (!HStateTable.Role) HStateTable.Role = {};
HStateTable.Renderer = (function() {
   const dsName = 'tableConfig';
   const triggerClass = 'state-table';
   const cellTraits = HStateTable.CellTrait;
   const columnTraits = HStateTable.ColumnTrait;
   const tableRoles = HStateTable.Role;
   const controls = { // A role applied to the table control elements
      controlElement(element, text, handler, event) {
         const anchor = document.createElement('a');
         anchor.textContent = text;
         handler ||= 'clickHandler';
         if (handler != 'none') {
            event ||= 'click';
            const func = function(ev) { this[handler](ev, text) };
            anchor.addEventListener(event, func.bind(this));
         }
         const item = document.createElement(element);
         item.append(anchor);
         return item;
      }
   };
   class Cell {
      constructor(column, row) {
         this.column = column;
         this.row = row;
         this.wrappableMethods = ['getValue'];
      }
      getValue() {
         const value = this.row.result[this.column.name];
         if (typeof value == 'object') return value;
         return { value: value };
      }
      render() {
         const cell = document.createElement('td');
         const content = this.getValue();
         if (content.wrapperClass) { cell.className = content.wrapperClass }
         const node = document.createTextNode(content.value);
         if (content.link) {
            const link = document.createElement('a');
            link.href = content.link;
            link.append(node);
            cell.append(link);
         }
         else { cell.append(node) }
         return cell;
      }
   };
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
      applyTraits(cell) {
         for (const trait of this.cellTraits) {
            for (const method of cell.wrappableMethods) {
               const around = cellTraits[trait][method];
               if (!around) continue;
               const original = cell[method].bind(cell);
               cell[method] = function() { return around(original) };
            }
         }
      }
      createCell(row) {
         const cell = new Cell(this, row);
         this.applyTraits(cell);
         return cell;
      }
      render() {
         const label   = this.label || this.name;
         const handler = this.sortable ? 'sortHandler' : 'none';
         const cell    = this.controlElement('th', label, handler);
         if (this.sortable && this.table.state('sortColumn') == this.name) {
            const symbol = this.sortDesc ? '▾' : '▴';
            cell.append(document.createTextNode(symbol));
         }
         return cell;
      }
      sortHandler(event, text) {
         event.preventDefault();
         this.sortDesc = !this.sortDesc;
         this.table.resultset.search({
            sortColumn: this.name, sortDesc: this.sortDesc
         });
         this.table.redraw();
      }
   };
   Object.assign(Column.prototype, controls);
   class PageControl {
      constructor(table) {
         this.className = 'page-control';
         this.enablePaging = table.properties['enable-paging'];
         this.list = document.createElement('ul');
         this.list.className = this.className;
         this.pagingText = 'Page %current_page of %last_page';
         this.table = table;
      }
      clickHandler(event, text) {
         event.preventDefault();
         let page = this.table.state('page');
         const lastPage = this.lastPage();
         if (text == 'first') { page = this.firstPage() }
         else if (text == 'prev' && page > 1) { page -= 1 }
         else if (text == 'next' && page < lastPage) { page += 1 }
         else if (text == 'last') { page = lastPage }
         this.table.resultset.search({ page: page });
         this.table.redraw();
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
         const list = document.createElement('ul');
         list.className = this.className;
         for (const text of ['first', 'prev', 'page', 'next', 'last']) {
            let elem;
            if (text == 'page') {
               elem = document.createTextNode(this.interpolatePageText());
            }
            else if (((text == 'first' || text == 'prev') && atFirst)
                     ||((text == 'next' || text == 'last') && atLast)) {
               elem = this.controlElement('li', text, 'none');
               elem.className = 'disabled';
            }
            else { elem = this.controlElement('li', text) }
            list.append(elem);
            list.append(document.createTextNode('\xA0'));
         }
         container.replaceChild(list, this.list);
         this.list = list;
      }
      renderPageControlNoCount(container) {
         const currentPage = this.table.state('page');
         const atFirst = !!(currentPage <= this.firstPage());
         const atLast  = !!(currentPage >= this.table.rowCount);
         const list = document.createElement('ul');
         list.className = this.className;
         for (const text of ['first', 'prev', 'page', 'next']) {
            let elem;
            if (text == 'page') {
               elem = document.createTextNode('Page\xA0' + currentPage);
            }
            else if (((text == 'first' || text == 'prev') && atFirst)
                     || (text == 'next' && atLast)) {
               elem = this.controlElement('li', text, 'none');
               elem.className = 'disabled';
            }
            else { elem = this.controlElement('li', text) }
            list.append(elem);
            list.append(document.createTextNode('\xA0'));
         }
         container.replaceChild(list, this.list);
         this.list = list;
      }
      totalRecords() {
         return this.table.properties['total-records'];
      }
   }
   Object.assign(PageControl.prototype, controls);
   class PageSizeControl {
      constructor(table) {
         this.className = 'page-size-control';
         this.enablePaging = table.properties['enable-paging'];
         this.list = document.createElement('ul')
         this.list.className = this.className;
         this.table = table;
      }
      clickHandler(event, size) {
         event.preventDefault();
         this.table.resultset.search({ pageSize: size });
         this.table.redraw();
      }
      render(container) {
         if (!this.enablePaging) return;
         const sizes = [10, 20, 50, 100];
         const maxPageSize = this.table.properties['max-page-size'] || 0;
         if (maxPageSize > 100) sizes.push(maxPageSize);
         const list = document.createElement('ul');
         list.className = this.className;
         list.append(this.controlElement('li','Showing up to\xA0','none'));
         for (const size of sizes) {
            if (size > 10) list.append(document.createTextNode(',\xA0'));
            const item = this.controlElement('li', size);
            if (size == this.table.state('pageSize'))
               item.className = 'selected-page-size'
            list.append(item);
         }
         list.append(this.controlElement('li', '\xA0rows', 'none'));
         container.replaceChild(list, this.list);
         this.list = list;
      }
   }
   Object.assign(PageSizeControl.prototype, controls);
   class ParameterMap {
      constructor() {
         this._nameMap = {
            filterColumn: 'filter_column',
            filterValue: 'filter_value',
            page: 'page',
            pageSize: 'page_size',
            sortColumn: 'sort_column',
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
      async sucks(url) {
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
         const response = await this.sucks(this.prepareURL());
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
         if (sortColumn) url.searchParams.set(nameMap('sort'), sortColumn);
         else url.searchParams.delete(nameMap('sort'));
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
         const row = document.createElement('tr');
         for (const cell of this.cells) { row.append(cell.render()) }
         return row;
      }
   };
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
         this.body = document.createElement('tbody');
         this.columns = [];
         this.container = container;
         this.header = document.createElement('thead');
         this.name = config['name'];
         this.properties = config['properties'];
         this.roles = config['roles'];
         this.rows = [];
         this.rowCount = 0;
         this.table = document.createElement('table');
         this.wrappableMethods = [
            'renderBottomLeftControl', 'renderBottomRightControl',
            'renderCreditControl',     'renderTitleControl',
            'renderTopLeftControl',    'renderTopRightControl',
         ];
         this.parameterMap = new ParameterMap();
         this.resultset = new Resultset(this);
         this._state = new State(this);

         for (const column of (config['columns'] || [])) {
            this.columns.push(new Column(this, column));
         }

         this.applyRoles();
         this.table.id = this.name;
         this.table.append(this.header);
         this.table.append(this.body);

         this.titleControl = document.createElement('div');
         this.titleControl.className = 'title-control';
         this.container.append(this.titleControl);
         this.topLeftControl = document.createElement('div');
         this.topLeftControl.className = 'top-left-control';
         this.container.append(this.topLeftControl);
         this.topRightControl = document.createElement('div');
         this.topRightControl.className = 'top-right-control';
         this.container.append(this.topRightControl);

         this.container.append(this.table);

         this.bottomLeftControl = document.createElement('div');
         this.bottomLeftControl.className = 'bottom-left-control';
         this.container.append(this.bottomLeftControl);
         this.bottomRightControl = document.createElement('div');
         this.bottomRightControl.className = 'bottom-right-control';
         this.container.append(this.bottomRightControl);
         this.creditControl = document.createElement('div');
         this.creditControl.className = 'credit-control';
         this.container.append(this.creditControl);

         this.pageControl = new PageControl(this);
         this.bottomLeftControl.append(this.pageControl.list);
         this.pageSizeControl = new PageSizeControl(this);
         this.bottomRightControl.append(this.pageSizeControl.list);
      }
      applyRoles() {
         for (const [roleName, config] of Object.entries(this.roles)) {
            const traitName = config['trait_name'] || roleName;
            const initialiser = tableRoles[traitName]['initialise'];
            if (initialiser) initialiser(this);
            for (const method of this.wrappableMethods) {
               if (!tableRoles[traitName][method]) continue;
               const around = tableRoles[traitName][method].bind(this);
               const original = this[method].bind(this);
               this[method] = function() { return around(original) };
            }
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
         this.renderTitleControl();
         this.renderTopLeftControl();
         this.renderTopRightControl();
         this.renderHeader();
         this.renderRows();
         this.renderBottomLeftControl();
         this.renderBottomRightControl();
         this.renderCreditControl();
      }
      render() {
         this.redraw();
      }
      renderHeader() {
         const row = document.createElement('tr');
         for (const column of this.columns) { row.append(column.render()) }
         const thead = document.createElement('thead');
         thead.append(row);
         this.table.replaceChild(thead, this.header);
         this.header = thead;
      }
      renderBottomLeftControl() {
         this.pageControl.render(this.bottomLeftControl);
         return this.bottomLeftControl;
      }
      renderBottomRightControl() {
         this.pageSizeControl.render(this.bottomRightControl);
         return this.bottomRightControl;
      }
      renderCreditControl() {
         return this.creditControl;
      }
      renderNoData() {
         const cell = document.createElement('td');
         cell.setAttribute('colspan', this.columns.length);
         const message = this.properties['no-data-message'];
         cell.append(document.createTextNode(message));
         const row = document.createElement('tr');
         row.append(cell)
         return row;
      }
      async renderRows() {
         this.rows = [];
         this.rowCount = 0;
         let row;
         while (row = await this.nextRow()) { this.rows.push(row) }
         this.rowCount = this.rows.length;
         const tbody = document.createElement('tbody');
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
   const tables = {};
   const createTables = function(els) {
      for (const el of els) {
         const table = new Table(el, JSON.parse(el.dataset[dsName]));
         tables[table.name] = table;
         table.render();
      }
   };
   let tableCreation = true;
   return {
      initialise: function() {
         HStateTable.Util.onReady(function() {
            createTables(document.getElementsByClassName(triggerClass));
            tableCreation = false;
         });
      },
   };
})();
HStateTable.Renderer.initialise();
