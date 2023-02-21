// Package HStateTable.Util
if (!window.HStateTable) window.HStateTable = {};
HStateTable.Util = (function () {
   const onReady = function(callback) {
      if (document.readyState != 'loading') callback();
      else if (document.addEventListener)
         document.addEventListener('DOMContentLoaded', callback);
      else document.attachEvent('onreadystatechange', function() {
         if (document.readyState == 'complete') callback();
      });
   };

   return {
      onReady: onReady,
   };
})();
// Package HStateTable.Renderer
if (!window.HStateTable) window.HStateTable = {};
if (!HStateTable.Column) HStateTable.Column = {};
if (!HStateTable.Column.Trait) HStateTable.Column.Trait = {};
HStateTable.Renderer = (function() {
   const dsName = 'tableConfig';
   const triggerClass = 'state-table';
   const columnTraits = HStateTable.Column.Trait;
   const controls = { // A role applied to the table control elements
      controlElement(element, text, handler, event) {
         const anchor = document.createElement('a');
         anchor.textContent = text;
         handler ||= 'clickHandler';
         if (handler != 'none') {
            event ||= 'click';
            const func = function(ev) { this[handler](ev, text); };
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
      createElementByType(value) {
         const type = typeof(value);
         if (type == 'number' || type == 'string') {
            return document.createTextNode(value);
         }
         else if (type == 'object') {
            const node = document.createTextNode(value.value);
            if (value.link) {
               const link = document.createElement('a');
               link.href = value.link;
               link.append(node)
               return link;
            }
            return node;
         }
      }
      getValue() {
         return this.row.result[this.column.name];
      }
      render() {
         const cell = document.createElement('td');
         cell.append(this.createElementByType(this.getValue()));
         return cell;
      }
   };
   class Column {
      constructor(table, config) {
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
         for (const trait of this.traits) {
            for (const method of cell.wrappableMethods) {
               const around = columnTraits[trait][method];
               if (!around) continue;
               const original = cell[method].bind(cell);
               cell[method] = function() { return around(original()); };
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
         this.table.resultset.search({}, {
            sortColumn: this.name, sortDesc: this.sortDesc
         });
         this.table.redraw();
      }
   };
   Object.assign(Column.prototype, controls);
   class PageControl {
      constructor(table) {
         this.container = table.container;
         this.list = document.createElement('ul');
         this.list.className = 'page-control';
         this.table = table;
      }
      clickHandler(event, text) {
         event.preventDefault();
         let page = this.table.state('page');
         if (text == 'prev' && page > 1) { page -= 1 }
         else if (text == 'next') { page += 1 }
         this.table.resultset.search({}, { page: page });
         this.table.redraw();
      }
      render() {
         for (const text of ['prev', 'next']) {
            this.list.append(this.controlElement('li', text));
            this.list.append(document.createTextNode(' '));
         }
         this.container.append(this.list);
      }
   }
   Object.assign(PageControl.prototype, controls);
   class PageSizeControl {
      constructor(table) {
         this.container = table.container;
         this.list = document.createElement('ul');
         this.list.className = 'page-size-control';
         this.table = table;
      }
      clickHandler(event, size) {
         event.preventDefault();
         this.table.resultset.search({}, { pageSize: size });
         this.table.redraw();
      }
      render() {
         for (const size of [10, 20, 50, 100]) {
            if (size > 10) this.list.append(document.createTextNode(', '));
            this.list.append(this.controlElement('li', size));
         }
         this.container.append(this.list);
      }
   }
   Object.assign(PageSizeControl.prototype, controls);
   class Resultset {
      constructor(table, config) {
         const properties = config['properties'];
         this.dataURL = properties['data-url'];
         this.enablePaging = properties['enable-paging'];
         this.index = 0;
         this.maxPageSize = properties['max-page-size'] || null;
         this.records = [];
         this.table = table;
         this.totalRecords = 0;
      }
      async sucks(url) {
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
         const filterColumn = state('filterColumn');
         const filterValue = state('filterValue');
         if (filterColumn && filterValue) {
            url.searchParams.set('filter_column', filterColumn);
            url.searchParams.set('filter_value', filterValue);
         }
         else {
            url.searchParams.delete('filter_column');
            url.searchParams.delete('filter_value');
         }
         if (this.enablePaging) {
            url.searchParams.set('page', state('page'));
            url.searchParams.set('page_size', state('pageSize'));
         }
         else {
            url.searchParams.delete('page');
            url.searchParams.delete('page_size');
         }
         const sortColumn = state('sortColumn');
         if (sortColumn) url.searchParams.set('sort', sortColumn);
         else url.searchParams.delete('sort');
         const sortDesc = state('sortDesc');
         if (sortColumn && sortDesc) url.searchParams.set('desc', sortDesc);
         else url.searchParams.delete('desc');
         return url;
      }
      reset() {
         this.index = 0;
         return this;
      }
      search(where, options) {
         const column = Object.keys(where)[0] || null;
         const value  = column ? (where[column] || null) : null;
         const state  = this.table.state.bind(this.table);
         if (column && value) {
            state('filterColumn', column);
            state('filterValue', value);
         }
         for (const [k, v] of Object.entries(options)) { state(k, v); }
         if (this.maxPageSize && state('pageSize') > this.maxPageSize)
            state('pageSize', this.maxPageSize);
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
         for (const cell of this.cells) { row.append(cell.render()); }
         return row;
      }
   };
   class State {
      constructor() {
         this.filterColumn = null;
         this.filterValue = null;
         this.page = 1;
         this.pageSize = 20;
         this.search = null;
         this.sortColumn = null;
         this.sortDesc = false;
      }
   }
   class Table {
      constructor(container, config) {
         this._state = new State();
         this.body = document.createElement('tbody');
         this.columns = [];
         this.container = container;
         this.header = document.createElement('thead');
         this.name = config['name'];
         this.properties = config['properties'];
         this.resultset = new Resultset(this, config);
         this.rows = [];
         this.table = document.createElement('table');

         this.pageControl = new PageControl(this);
         this.pageSizeControl = new PageSizeControl(this);

         for (const column of (config['columns'] || [])) {
            this.columns.push(new Column(this, column));
         }

         this.container.append(this.table);
         this.table.append(this.header);
         this.table.append(this.body);
      }
      async nextResult() {
         return await this.resultset.next();
      }
      async nextRow() {
         const result = await this.nextResult()
         return result ? new Row(this, result) : undefined;
      }
      redraw() {
         this.renderHeader();
         this.renderRows();
      }
      render() {
         this.redraw();
         this.pageControl.render();
         this.pageSizeControl.render();
      }
      renderHeader() {
         const row = document.createElement('tr');
         for (const column of this.columns) { row.append(column.render()); }
         const thead = document.createElement('thead');
         thead.append(row);
         this.table.replaceChild(thead, this.header);
         this.header = thead;
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
         let row;
         while (row = await this.nextRow()) { this.rows.push(row); }
         const tbody = document.createElement('tbody');
         if (!this.rows[0]) { tbody.append(this.renderNoData()); }
         else { for (row of this.rows) { tbody.append(row.render()); } }
         this.table.replaceChild(tbody, this.body);
         this.body = tbody;
      }
      state(key, value) {
         if (!this._state.hasOwnProperty(key)) return;
         if (typeof value !== 'undefined') this._state[key] = value;
         return this._state[key];
      }
   };
   const tables = {};
   let tableCreation = true;
   const createTables = function(els) {
      for (const el of els) {
         const table = new Table(el, JSON.parse(el.dataset[dsName]));
         tables[table.name] = table;
         table.render();
      }
   };

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
// Package HStateTable.Column.Trait.Date
HStateTable.Column.Trait.Date = (function() {
   return {
      getValue: function(value) {
         return new Date(value).toLocaleDateString();
      }
   };
})();
// Package HStateTable.Column.Trait.Time
HStateTable.Column.Trait.Time = (function() {
   return {
      getValue: function(value) {
         const options = { hour: "2-digit", minute: "2-digit" };
         return new Date(value).toLocaleTimeString([], options);
      }
   };
})();
// Package HStateTable.Column.Trait.DateTime
HStateTable.Column.Trait.DateTime = (function() {
   return {
      getValue: function(value) {
         const datetime = new Date(value);
         const date = datetime.toLocaleDateString();
         const options = { hour: "2-digit", minute: "2-digit" };
         const time = datetime.toLocaleTimeString([], options);
         return  date + ' ' + time;
      }
   };
})();
