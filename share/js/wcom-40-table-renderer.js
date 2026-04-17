/** -*- coding: utf-8; -*-
    @file HTML StateTable - Renderer
    @classdesc Render tables
    @author pjfl@cpan.org (Peter Flanigan)
    @version 0.2.33
    @alias WCom/Table
*/
if (!WCom.Table) WCom.Table = {};
if (!WCom.Table.CellTrait) WCom.Table.CellTrait = {};
if (!WCom.Table.ColumnTrait) WCom.Table.ColumnTrait = {};
if (!WCom.Table.RowTrait) WCom.Table.RowTrait = {};
if (!WCom.Table.Role) WCom.Table.Role = {};
WCom.Table.Renderer = (function() {
   const dsName       = 'tableConfig';
   const triggerClass = 'state-table';
   const Navigation   = WCom.Navigation;
   const CellTraits   = WCom.Table.CellTrait;
   const ColumnTraits = WCom.Table.ColumnTrait;
   const RowTraits    = WCom.Table.RowTrait;
   const TableRoles   = WCom.Table.Role;
   const Utils        = WCom.Util;
   /** @class
       @classdesc Cell object
       @alias Table/Cell
   */
   class Cell {
      /** @constructs
          @desc Construct the cell object
          @param {object} column
          @param {object} row
      */
      constructor(column, row) {
         this.column = column;
         this.row    = row;
      }
      /** @function
          @desc Returns the cells value from the result object provided by
             the row
          @return {object} Key of 'value'
      */
      getValue(attr) {
         const value = this.row.result[this.column.name];
         if (typeof value == 'object') return value;
         return { value: value };
      }
      /** @function
          @desc Renders the cell object
          @return {element} The rendered table cell element
      */
      render() {
         const attr = {};
         const { append, link, value } = this.getValue(attr);
         let cell;
         if (this.isHTML(value)) {
            cell = this.h.td(attr, this.h.frag(value));
            if (this.isHTMLOfClass(value, triggerClass))
               WCom.Table.Renderer.scan(cell);
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
   Object.assign(Cell.prototype, Utils.Markup); // Apply role
   Object.assign(Cell.prototype, Utils.Modifiers); // Apply another role
   Object.assign(Cell.prototype, Utils.String); // Apply another role
   /** @class
       @classdesc Column object
       @alias Table/Column
   */
   class Column {
      /** @constructs
          @desc Construct the column object
          @param {object} table
          @param {object} config
      */
      constructor(table, config) {
         this.table        = table;
         this.rs           = table.resultset;
         this.cellTraits   = config['cell_traits'] || [];
         this.displayed    = config['displayed'];
         this.downloadable = config['downloadable'];
         this.filterable   = config['filterable'];
         this.label        = config['label'];
         this.maxWidth     = config['max_width']
            ? ('max-width:' + config['max_width'] + ';') : '';
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
      /** @function
          @desc Creates the {@link Table/Cell cell} object
          @param {object} row
          @return {element} The rendered table cell element
      */
      createCell(row) {
         const cell = new Cell(this, row);
         this.applyTraits(cell, CellTraits, this.cellTraits);
         const result = row.result[this.name];
         if (result.cellTraits && !this.options['notraits']) {
            this.applyTraits(cell, CellTraits, result.cellTraits);
         }
         return cell;
      }
      /** @function
          @desc Renders the column object
          @return {element} The rendered table header element
      */
      render() {
         this.rowSelector = {};
         const attr = { style: '' };
         let content = [this.label || this.ucfirst(this.name)];
         if (this.title) attr.title = this.title;
         if (this.maxWidth) attr.style += this.maxWidth;
         if (this.minWidth) attr.style += this.minWidth;
         if (this.width) attr.style += this.width;
         if (this.sortable) {
            if (this.rs.state('sortColumn') == this.name) {
               attr.className = 'active-sort-column';
            }
            content = [this.h.a({
               className: 'column-header', onclick: this.sortHandler
            }, content[0])];
         }
         else if (content[0].match(/[^ ]/)) {
            content = [this.h.span({ className: 'column-header' }, content[0])];
         }
         this.header = this.h.th(attr, content);
         return this.header;
      }
   };
   Object.assign(Column.prototype, Utils.Markup);
   Object.assign(Column.prototype, Utils.Modifiers);
   Object.assign(Column.prototype, Utils.String);
   /** @class
       @classdesc Row object
       @alias Table/Row
   */
   class Row {
      /** @constructs
          @desc Construct the row object
          @param {object} table
          @param {object} result
          @param {integer} index
      */
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
      /** @function
          @desc Renders the row object
          @param {object} attr
          @return {element} The rendered table row element
      */
      render(attr) {
         attr ||= {};
         const row = this.h.tr(attr);
         for (const cell of this.cells) {
            if (cell.column.displayed) row.append(cell.render());
         }
         return row;
      }
   };
   Object.assign(Row.prototype, Utils.Markup);
   Object.assign(Row.prototype, Utils.Modifiers);
   /** @class
       @classdesc State object
       @alias Table/State
   */
   class State {
      /** @constructs
          @desc Construct the state object
          @param {object} table
      */
      constructor(table) {
         this.page       = 1;
         this.pageSize   = table.properties['page-size'];
         this.prevPage   = 0;
         this.sortColumn = table.properties['sort-column'];
         this.sortDesc   = table.properties['sort-desc'];
      }
   }
   /** @class
       @classdesc Resultset object
       @alias Table/Resultset
   */
   class Resultset {
      /** @constructs
          @desc Construct the resultset object
          @param {object} table
      */
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
      /** @function
          @desc Extends the {@link Table/State state} object by adding the
             key/value to it
          @param {string} key
          @param {string} value
      */
      extendState(key, value) {
         this._state[key] = value;
      }
      /** @function
          @desc Returns the current state values for the supplied keys
          @param {array} attrs List of state object keys
          @return {object} Selected state object key/value pairs
      */
      getState(attrs) {
         const state = {};
         for (const attr of attrs) { state[attr] = this.state(attr) || '' }
         return state;
      }
      /** @function
          @desc Accessor/mutator for the 'this.parameterMap'. If 'key' is
             undefined return the whole map
          @param {string} key
          @param {string} value
          @return {string}
      */
      nameMap(key, value) {
         if (typeof key == 'undefined') return this.parameterMap;
         if (typeof value != 'undefined') this.parameterMap[key] = value;
         return this.parameterMap[key];
      }
      /** @function
          @desc Iterator which returns the next object from the array of
             object returned by the server
          @return {object}
      */
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
      /** @function
          @desc Calls {@link Table/Resultset#reset reset} and
             {@link Table/Table#redraw redraws} the table
          @return {object} Self referential object. Allows method chaining
      */
      redraw() {
         this.reset();
         this.table.redraw();
         return this;
      }
      /** @function
          @desc Resets the iterator index to zero
          @return {object} Self referential object. Allows method chaining
      */
      reset() {
         this.index = 0;
         return this;
      }
      /** @function
          @desc Applies the key/value pairs provided to the
             {@link Table/State state} object
          @param {object} options
          @return {object} Self referential object. Allows method chaining
      */
      search(options) {
         for (const [k, v] of Object.entries(options)) { this.state(k, v) }
         return this.reset();
      }
      /** @function
          @desc Accessor/mutator for the {@link Table/State state} object
          @param {string} key
          @param {string} value
          @return {string}
      */
      state(key, value) {
         if (typeof value !== 'undefined') {
            if (key == 'page' || key == 'pageSize')
               this._state['prevPage'] = this._state['page'];
            this._state[key] = value;
            if (key == 'pageSize') this._state['page'] = 1;
         }
         return this._state[key];
      }
      /** @function
          @desc Returns true if any of the state attribute values have
             changed
          @param {object} previousState
          @return {boolean}
      */
      stateChanged(previousState) {
         for (const [key, previous] of Object.entries(previousState)) {
            const current = this.state(key) || '';
            if (previous != current) return true;
         }
         return false;
      }
   };
   Object.assign(Resultset.prototype, Utils.Bitch);
   Object.assign(Resultset.prototype, Utils.Markup);
   /** @class
       @classdesc Table object
       @alias Table/Table
   */
   class Table {
      /** @constructs
          @desc Creates a new {@link Table/Resultset resultset}.
             Applies roles the table object both before and after
             the {@link Table/Columns columns} are created
          @param {element} container The element containing the table
          @param {object} config
          @property {array} config.columns
          @property {string} config.name
          @property {object} config.properties
          @property {object} config.roles
          @property {object} config.row-traits
          @property {string} properties.caption
          @property {string} properties.icons
          @property {string} properties.max-width
          @property {string} properties.min-width
          @property {string} properties.render-style
          @property {string} properties.title-location
      */
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
         this.icons         = this.properties['icons'];
         this.modal         = {};
         this.pageManager   = this._getPageManager(this.properties);
         this.renderStyle   = this.properties['render-style'];
         this.rows          = [];
         this.rowCount      = 0;
         this.resultset     = new Resultset(this);
         this.titleLocation = this.properties['title-location'] || 'inner';
         this.topContent    = false;
         const tableAttr    = { id: this.name, className: this.name };
         this.table         = this.h.table(tableAttr);
         if (this.properties['max-width']) this.table.style.setProperty(
            'max-width', this.properties['max-width']
         );
         if (this.properties['min-width']) this.table.style.setProperty(
            'min-width', this.properties['min-width']
         );
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
         this.topControl = this.h.div({ className });
         this.topLeftControl = this.h.div({ className: 'top-left-control' });
         this.topControl.append(this.topLeftControl);
         this.topRightControl = this.h.div({ className: 'top-right-control' });
         this.topControl.append(this.topRightControl);

         className = 'bottom-control';
         if (this.bottomContent) className += ' visible';
         this.bottomControl = this.h.div({ className });
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
      /** @function
          @desc Appends the content to the container
          @param {element} container
          @param {array} content
      */
      appendContainer(container, content) {
         for (const el of content) { container.append(el); }
      }
      /** @function
          @desc Applies the table roles
          @param {boolean} before If true only apply the before column
             creation roles
      */
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
      /** @function
          @desc Creates a new {@link Table/Column column} object from the
             provided configuration
          @param {object} config
          @return {object} A new column object
      */
      createColumn(config) {
         return new Column(this, config);
      }
      /** @function
          @async
          @desc Returns the @{link Table/Resultset#next next} result object
          @return {object}
      */
      async nextResult() {
         return await this.resultset.next();
      }
      /** @function
          @async
          @desc Returns the next {@link Table/Row row} object
          @param {integer} index
          @return {object} A new row object
      */
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
      /** @function
          @desc Orders the content. If the 'titleLocation' attribute is set to
             'outer' the title element is rendered before the top element.
             Setting it to 'inner' reverses this. Also applies to the credit
             and bottom elements
          @return {array}
      */
      orderedContent() {
         let content;
         if (this.titleLocation == 'outer') {
            content = [
               this.titleControl, this.topControl,
               this.table,
               this.bottomControl, this.creditControl
            ];
         }
         else {
            content = [
               this.topControl, this.titleControl,
               this.table,
               this.creditControl, this.bottomControl
            ];
         }
         const caption = this.renderCaption();
         if (caption) content.unshift(caption);
         return content;
      }
      /** @function
          @desc Prepares the data request URL
          @param {object} args
          @return {object} A URL object
      */
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
      /** @function
          @async
          @desc Reads all the rows
      */
      async readRows() {
         this.rows = [];
         let index = 0;
         let row;
         while (row = await this.nextRow(index++)) { this.rows.push(row) }
      }
      /** @function
          @desc Redraws the table
      */
      redraw() {
         this.render();
      }
      /** @function
          @async
          @desc Renders the table
      */
      async render() {
         this.renderHeader();
         await this.renderRows();
         this.renderTopLeftControl();
         this.renderTopRightControl();
         this.renderTitleControl();
         this.renderCreditControl();
         this.renderBottomLeftControl();
         this.renderBottomRightControl();
         this.animateButtons(this.container);
      }
      /** @function
          @desc Renders the body of the table
      */
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
      /** @function
          @desc Renders the bottom left control element
          @return {element}
      */
      renderBottomLeftControl() {
         return this.bottomLeftControl;
      }
      /** @function
          @desc Renders the bottom right control element
          @return {element}
      */
      renderBottomRightControl() {
         return this.bottomRightControl;
      }
      /** @function
          @desc Renders the caption if it has some length
          @return {element}
      */
      renderCaption() {
         if (!this.caption.length) return;
         return this.h.div({ className: 'caption' }, this.caption);
      }
      /** @function
          @desc Renders the control element after the table
          @return {element}
      */
      renderCreditControl() {
         return this.creditControl;
      }
      /** @function
          @desc Renders the header element
      */
      renderHeader() {
         const row = this.h.tr();
         for (const column of this.columns) {
            if (column.displayed) row.append(column.render());
         }
         const thead = this.h.thead(row);
         this.table.replaceChild(thead, this.header);
         this.header = thead;
      }
      /** @function
          @desc Renders nothing
      */
      renderNoData() {
         const message = this.properties['no-data-message'];
         const cell    = this.h.td({
            className: 'no-data', colSpan: this.columns.length
         }, message);
         const tbody   = this.h.tbody(this.h.tr(cell));
         this.table.replaceChild(tbody, this.body);
         this.body = tbody;
      }
      /** @function
          @desc Renders one row
          @param {element} container
          @param {object} row
          @param {string} className
          @return {element}
      */
      renderRow(container, row, className) {
         const rendered = row.render({ className: className });
         container.append(rendered);
         return rendered;
      }
      /** @function
          @async
          @desc Renders all rows
      */
      async renderRows() {
         await this.readRows();
         if (!this.rows.length) return this.renderNoData();
         this.renderBody();
         this.rowCount = this.rows.length;
         if (this.pageManager) this.pageManager.onContentLoad();
      }
      /** @function
          @desc Renders the control element before the table
          @return {element}
      */
      renderTitleControl() {
         return this.titleControl;
      }
      /** @function
          @desc Renders the top left control element
          @return {element}
      */
      renderTopLeftControl() {
         return this.topLeftControl;
      }
      /** @function
          @desc Renders the top right control element
          @return {element}
      */
      renderTopRightControl() {
         return this.topRightControl;
      }
      /** @function
          @param {string} control
          @desc Sets the control state
      */
      setControlState(control) {
         if (control.match(/Bottom/)) this.bottomContent = true;
         if (control.match(/Top/)) this.topContent = true;
      }
      _getPageManager(properties) {
         const manager = this.lookupStatic(properties['page-manager']);
         return manager ? manager : Navigation;
      }
   };
   Object.assign(Table.prototype, Utils.Markup);
   Object.assign(Table.prototype, Utils.Modifiers);
   Object.assign(Table.prototype, Utils.String);
   /** @class
       @classdesc Factory object
       @alias Table/Factory
   */
   class Factory {
      /** @construct
          @desc An instance of the Factory is created when the code loads.
             It registers the scan method to execute on page load
      */
      constructor() {
         this.tables = {};
         WCom.Util.Event.registerOnload(this.scan.bind(this));
      }
      /** @function
          @async
          @desc Resolves when this factory has finished creating tables
          @return {promise}
      */
      isConstructing() {
         return new Promise(function(resolve) {
            setTimeout(() => {
               if (!this._isConstructing) resolve(false);
            }, 250);
         }.bind(this));
      }
      /** @function
          @async
          @desc Scan the content for elements with the trigger class. Creates
             {@link Table/Table tables} and calls their
             {@link Table/Table#render render} method
          @param {element} content The element to scan
          @param {object} options Currently unused
      */
      async scan(content = document, options = {}) {
         this._isConstructing = true;
         const promises = [];
         for (const el of content.getElementsByClassName(triggerClass)) {
            const table = new Table(el, JSON.parse(el.dataset[dsName]));
            this.tables[table.name] = table;
            promises.push(table.render());
         }
         await Promise.all(promises);
         this._isConstructing = false;
      }
   }
   const factory = new Factory();
   /** @module Table
   */
   return {
      /** @function
          @desc Calls {@link Table/Factory#isConstructing method} on
             the {@link Table/Factory Factory} object
      */
      isConstructing: factory.isConstructing.bind(factory),
      /** @function
          @desc Calls {@link Table/Factory#scan method} on
             the {@link Table/Factory Factory} object
      */
      scan: factory.scan.bind(factory),
      /** @object
          @desc An object containing the current tables
          @return {object}
      */
      tables: factory.tables
   };
})();
