// Package HStateTable.Role.Active
HStateTable.Role.Active = (function() {
   class Active {
      constructor(table, methods) {
         this.table = table;
         this.rs = table.resultset;
         const config = table.roles['active'];
         this.enabled = config['enabled'];
         this.label = config['label'];
         this.location = config['location'];
         this.controlLocation = this.location['control'];
         this.activeForm;
         this.showInactive = false;
         this.table.rowTraits['active'] = {};
         this.rs.extendState('showInactive', false);
         this.rs.nameMap('showInactive', 'show_inactive');
         this.handler = function(event) {
            this.showInactive = !this.showInactive;
            this.rs.search({ showInactive: this.showInactive }).redraw();
         }.bind(this);
         this.table.setControlState(this.controlLocation);
         const name = 'render' + this.controlLocation + 'Control';
         methods[name] = function(orig) {
            const container = orig();
            if (this.enabled) this.render(container);
            return container;
         }.bind(this);
         methods['prepareURL'] = function(orig, args) {
            args ||= {};
            const url = orig(args);
            const params = url.searchParams;
            const colName = this.rs.nameMap('showInactive');
            if (this.rs.state('showInactive')) params.set(colName, true);
            else params.delete(colName);
            return url;
         }.bind(this);
      }
      render(container) {
         const content = [ this.label ];
         const box = this.h.checkbox({
            checked: this.showInactive, name: 'showInactive',
            onclick: this.handler
         });
         if (this.controlLocation.match(/Right/)) content.push(box);
         else content.unshift(box);
         const activeForm = this.h.form({
            className: 'active-control', id: this.table.name + 'Active'
         }, this.h.label({
            className: 'active-control-label', htmlFor: 'showInactive'
         }, content));
         this.activeForm = this.display(container, 'activeForm', activeForm);
      }
   }
   Object.assign(Active.prototype, HStateTable.Util.Markup);
   Object.assign(Active.prototype, HStateTable.Util.Modifiers);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.active = new Active(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Animation
HStateTable.Role.Animation = (function() { // TODO: Finish this
   class Animation {
      constructor(table, methods) {
         this.table = table;
         this.rs = table.resultset;
         methods['renderBody'] = this.renderScrollingBody.bind(this);
         methods['renderRow']  = this.renderRowWithDirection.bind(this);
      }
      direction() {
         const prev = this.rs.state('prevPage');
         if (prev > this.rs.state('page') && prev > 1) return 'down';
         return 'up';
      }
      renderRowWithDirection(orig, container, row, className) {
         const style = this.table.renderStyle;
         if (style != 'scroll') return orig(container, row, className);
         const rendered = row.render({ className: className });
         if (this.direction() == 'up') container.append(rendered);
         else container.prepend(rendered);
         return rendered;
      }
      renderScrollingBody(orig) {
         if (this.table.renderStyle != 'scroll') return orig();
         const body = this.table.body;
         const rows = this.table.rows;
         const size = this.rs.state('pageSize');
         if (this.direction() == 'up') this.renderScrollUp(body, rows, size);
         else this.renderScrollDown(body, rows, size);
         this.rs.state('prevPage', this.rs.state('page'));
      }
      renderScrollDown(body, rows, pageSize) {
         let className = body.children.length % 2 == 0 ? 'odd' : 'even';
         for (const row of rows.reverse()) {
            const child = body.lastChild;
            if (child && body.children.length == pageSize) child.remove();
            const rendered = this.table.renderRow(body, row, className);
            className = (className == 'odd') ? 'even' : 'odd';
         }
         if (rows.length < pageSize) {
            let child = body.children.item(rows.length);
            while (child) {
               child.remove();
               child = body.children.item(rows.length);
            }
         }
      }
      renderScrollUp(body, rows, pageSize) {
         let className = body.children.length % 2 == 0 ? 'even' : 'odd';
         for (const row of rows) {
            let child = body.firstChild;
            if (child && body.children.length == pageSize) child.remove();
            const rendered = this.table.renderRow(body, row, className);
            className = (className == 'odd') ? 'even' : 'odd';
         }
         if (rows.length < pageSize && this.rs.state('page') == 1) {
            while (body.children.length > rows.length)
               body.children.item(0).remove();
         }
      }
   }
   Object.assign(Animation.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.animation = new Animation(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Chartable
HStateTable.Role.Chartable = (function() {
   class Chartable {
      constructor(table, methods) {
         const config = table.roles['chartable'];
         this.columnNames = config['columns'] || [];
         this.chartConfig = config['config'];
         this.figureLocation = config['figure']['location'];
         this.chartable;
         this.previousState;
         this.series = config['series'] || {};
         this.stateAttr = config['state-attr'] || [];
         this.table = table;
         this.rs = table.resultset;
         methods['appendContainer'] = function(orig, container, content) {
            const location = this.figureLocation;
            const attr = { className: 'chart-container' };
            if (location == 'Left' || location == 'Right') {
               this.appendValue(attr, 'className', 'inline');
               const tableContainer = this.table.tableContainer;
               this.appendValue(tableContainer, 'className', 'inline');
            }
            this.chartable = this.h.div({ id: 'chartable' });
            const display = this.h.div(attr, this.h.figure(
               { className: 'highcharts-figure' }, this.chartable
            ));
            if (location == 'Top' || location == 'Left')
               content.unshift(display);
            else content.push(display);
            orig(container, content);
         }.bind(this);
         methods['render'] = function(orig){ this.render(orig) }.bind(this);
      }
      async render(orig) {
         orig();
         const state = this.rs.getState(this.stateAttr);
         if (!this.previousState) this.previousState = state;
         else if (!this.rs.stateChanged(this.previousState)) return;
         this.previousState = state;
         const url = this.table.prepareURL({ disablePaging: true });
         const { object } = await this.bitch.sucks(url);
         const results = object['records'];
         const series = [];
         for (const colName of this.columnNames) {
            const data = [];
            for (const result of results) {
               const name = result.name.value;
               data.push([ name, parseInt(result[colName]) ]);
            }
            const column = this.table.columnIndex[colName];
            series.push({ ...this.series, data: data, name: column.label });
         }
         const config = this.chartConfig;
         config['series'] = series;
         Highcharts.chart(this.chartable, config);
      }
   }
   Object.assign(Chartable.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.chartable = new Chartable(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.CheckAll
HStateTable.Role.CheckAll = (function() {
   class CheckAllControl {
      constructor(table, methods) {
         methods['createColumn'] = function(orig, table, config) {
            const column = orig(table, config);
            if (column.options['checkall'])
               this.applyTraits(column, HStateTable.ColumnTrait, ['CheckAll']);
            return column;
         };
      }
   }
   Object.assign(CheckAllControl.prototype, HStateTable.Util.Modifiers);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.checkAllControl = new CheckAllControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Configurable
HStateTable.Role.Configurable = (function() {
   class PreferenceHandlers{
      constructor(preference) {
         this.preference = preference;
         this.control = preference.control;
         this.rs = preference.rs;
         this.table = preference.table;
         this.functions = {};
         this.functions['changeHandler'] = function(event) {
            this.updatePreference();
            this.rs.redraw();
         }.bind(this);
         this.functions['clearHandler'] = function(event) {
            event.preventDefault();
            this.control.dialogHandler(event);
            this.clearPreference();
         }.bind(this);
         this.functions['dragEnterHandler'] = function(event) {
            this.preferenceTable().classList.add('dragover');
         }.bind(this);
         this.functions['dragLeaveHandler'] = function(event) {
            this.preferenceTable().classList.remove('dragover');
         }.bind(this);
         this.functions['dragOverHandler'] = function(event) {
            event.preventDefault();
            const id    = event.dataTransfer.getData('text');
            const moved = document.getElementById(id);
            const cell  = this.findCell(event.target);
            if (!cell) return;
            const row   = cell.parentNode;
            const rows  = Array.from(row.parentNode.children);
            if (rows.indexOf(row) > rows.indexOf(moved)) row.after(moved);
            else row.before(moved);
         }.bind(this);
         this.functions['dragStartHandler'] = function(event) {
            event.dataTransfer.setData('text', event.target.id);
         }.bind(this);
         this.functions['dropHandler'] = function(event) {
            event.preventDefault();
            this.functions['dragLeaveHandler'](event);
            const cell = this.findCell(event.target);
            if (!cell) return;
            const row  = cell.parentNode;
            const rows = Array.from(row.parentNode.children);
            this.table.columns = this.columnReorder(rows);
            this.rs.redraw();
         }.bind(this);
         this.functions['resetHandler'] = function(event) {
            event.preventDefault();
            this.resetPreference();
            this.preference.render();
            this.rs.redraw();
         }.bind(this);
         this.functions['saveHandler'] = function(event) {
            event.preventDefault();
            this.control.dialogHandler(event);
            this.savePreference();
         }.bind(this);
         this.functions['downloadHandler'] = function(event) {
            event.preventDefault();
            this.control.dialogHandler(event);
            this.table.downloadControl.downloadHandler(event);
         }.bind(this);
      }
      applyColumnOrder(order) {
         const columns = [];
         for (const columnName of order) {
            const column = this.table.columnIndex[columnName];
            if (column) columns.push(column);
         }
         this.table.columns = columns;
      }
      async clearPreference() {
         const json = JSON.stringify({ data: '', _verify: this.rs.token });
         await this.bitch.blows(this.control.url, { json: json });
         const url = this.table.prepareURL({ tableMeta: true });
         const { object } = await this.bitch.sucks(url);
         const order = object['column-order'];
         if (order) this.applyColumnOrder(order);
         for (const column of this.table.columns) {
            column.displayed = object['displayed'][column.name];
            column.downloadable = object['downloadable'][column.name];
         }
         this.rs.state('pageSize',   object['page-size']);
         this.rs.state('sortColumn', object['sort-column']);
         this.rs.state('sortDesc',   object['sort-desc']);
         this.table.renderStyle = object['render-style'];
         this.preference.form.initialState = this.preference.getState();
         this.rs.redraw();
      }
      columnReorder(rows) {
         const header = rows.shift();
         const order = [];
         for (const row of rows) order.push(row.id.split(/\./)[1]);
         const columns = [];
         const col0 = this.table.columns[0];
         if (col0.cellTraits.includes('Checkbox')) columns.push(col0);
         for (const columnName of order) {
            columns.push(this.table.columnIndex[columnName]);
         }
         return columns;
      }
      findCell(target) {
         let cell = target;
         while (cell.nodeName != 'TD') {
            cell = cell.parentNode;
            if (!cell) {
               throw new Error(`Drop handler lost plot: ${target.nodeName}`);
               return;
            }
         }
         return cell;
      }
      preferenceTable() {
         return this.preference.form.preferenceTable;
      }
      resetPreference() {
         const form = this.preference.form;
         const state = form.initialState;
         const order = state['columnOrder'];
         if (order) this.applyColumnOrder(order);
         for (const column of this.table.columns) {
            column.displayed = state['viewable'][column.name];
            column.downloadable = state['download'][column.name];
         }
         this.rs.state('pageSize', state['pageSize']);
         form.pageSize.value = state['pageSize'];
         this.table.renderStyle = state['renderStyle'];
         if (form.renderStyle) form.renderStyle.value = this.table.renderStyle;
         this.rs.state('sortColumn', state['sortColumn']);
         form.sortBy.value = state['sortColumn'];
         this.rs.state('sortDesc', state['sortDesc']);
         form.sortDesc.checked = state['sortDesc'];
      }
      async savePreference() {
         const data = this.updatePreference();
         const json = JSON.stringify({ data: data, _verify: this.rs.token });
         await this.bitch.blows(this.control.url, { json: json });
         this.preference.form.initialState = this.preference.getState();
         this.rs.redraw();
      }
      updatePreference() {
         const form = this.preference.form;
         const pageSize = form.pageSize.value;
         const renderStyle
               = form.renderStyle ? form.renderStyle.value : 'replace';
         const sortBy = form.sortBy.value;
         const sortDesc = form.sortDesc.checked;
         this.rs.search({
            pageSize: pageSize,
            sortColumn: sortBy,
            sortDesc: sortDesc
         });
         const data = { columns: {}, sort: { column: sortBy, desc: sortDesc } };
         data['column_order'] = this.table.columns.map(col => col.name);
         data['page_size'] = pageSize;
         this.table.renderStyle = data['render_style'] = renderStyle;
         for (const box of form.downBoxes) {
            const name = box.name.replace(/Down$/, '');
            data.columns[name] ||= {};
            data.columns[name]['download'] = box.checked;
            this.table.columnIndex[name]['downloadable'] = box.checked;
         }
         for (const box of form.viewBoxes) {
            const name = box.name.replace(/View$/, '');
            data.columns[name] ||= {};
            data.columns[name]['view'] = box.checked;
            this.table.columnIndex[name]['displayed'] = box.checked;
         }
         return data;
      }
   }
   Object.assign(PreferenceHandlers.prototype, HStateTable.Util.Markup);
   class PreferenceForm {
      constructor(preference) {
         this.preference = preference;
         this.handlers = preference.handlers.functions;
         this.initialState = preference.getState();
         this.table = preference.table;
         this.animation = this.table.roles['animation'] ? true : false;
         this.downloadable = this.table.roles['downloadable'] ? true : false;
         this.reorderable = this.table.roles['reorderable'] ? true : false;
         this.downBoxes = [];
         this.initialState;
         this.pageSize;
         this.preferenceTable;
         this.renderStyle;
         this.sortBy;
         this.sortDesc;
         this.viewBoxes = [];
      }
      renderButtons () {
         return this.h.div({ className: 'dialog-input dialog-buttons' }, [
            this.downloadable ? this.h.button({
               className: 'dialog-button-download',
               onclick: this.handlers['downloadHandler']
            }, 'Download') : '',
            this.h.div({ className: 'dialog-button-group' }, [
               this.h.button({
                  className: 'dialog-button-clear',
                  onclick: this.handlers['clearHandler']
               }, 'Clear'),
               this.h.button({
                  className: 'dialog-button-reset',
                  onclick: this.handlers['resetHandler'],
                  type: 'reset'
               }, 'Reset'),
               this.h.button({
                  className: 'dialog-button-save',
                  onclick: this.handlers['saveHandler']
               }, 'Save')
            ])
         ]);
      }
      renderCells(state, column) {
         const viewBox = this.h.checkbox({
            checked: state['viewable'][column.name],
            id: column.name + 'View', name: column.name + 'View',
            onchange: this.handlers['changeHandler']
         });
         this.viewBoxes.push(viewBox);
         let cell = this.h.td(column.label || this.ucfirst(column.name));
         cell.setAttribute('data-cell', 'Column Name');
         const cells = [cell];
         cell = this.h.td({ className: 'checkbox' }, viewBox);
         cell.setAttribute('data-cell', 'View');
         cells.push(cell);
         if (this.downloadable) {
            const downBox = this.h.checkbox({
               checked: state['download'][column.name],
               id: column.name + 'Down', name: column.name + 'Down',
            });
            this.downBoxes.push(downBox);
            cell = this.h.td({ className: 'checkbox' }, downBox);
            cell.setAttribute('data-cell', 'Download');
            cells.push(cell);
         }
         if (this.reorderable) {
            const orderControl = this.table.orderControl;
            cell = this.h.td({
               className: 'grab-handle-cell'
            }, this.h.div({
               className: 'grab-handle', title: orderControl.title
            }, orderControl.label));
            cell.setAttribute('data-cell', 'Order');
            cells.push(cell);
         }
         return cells;
      }
      renderHeaderCells() {
         return [
            this.h.th('Column'),
            this.h.th('View'),
            this.downloadable ? this.h.th('Download') : '',
            this.reorderable  ? this.h.th('Order')    : ''
         ];
      }
      render(state) {
         this.downBoxes = [];
         this.viewBoxes = [];
         const rows = [this.h.tr(this.renderHeaderCells())];
         const sortOptions = [ this.h.option({ value: '' }, '[ Default ]') ];
         for (const columnName of state['columnOrder']) {
            const column = this.table.columnIndex[columnName];
            if (!column.cellTraits.includes('Checkbox')) {
               rows.push(this.h.tr({
                  draggable: true,
                  id: 'preference-row.' + column.name,
                  ondragover: this.handlers['dragOverHandler'],
                  ondragstart: this.handlers['dragStartHandler']
               }, this.renderCells(state, column)));
            }
            if (column.sortable) {
               const option = { value: column.name };
               if (column.name == state['sortColumn'])
                  option.selected = 'selected';
               sortOptions.push(this.h.option(option, column.label));
            }
         }
         const sizeOptions = [];
         for (const size of [10, 20, 50, 100]) {
            const option = { value: size };
            if (size == state['pageSize']) option.selected = 'selected';
            sizeOptions.push(this.h.option(option, size));
         }
         this.pageSize = this.h.select({
            id: 'pageSize', name: 'pageSize',
            onchange: this.handlers['changeHandler']
         }, sizeOptions);
         this.sortBy = this.h.select({
            id: 'sortBy', name: 'sortBy',
            onchange: this.handlers['changeHandler']
         }, sortOptions);
         this.sortDesc = this.h.checkbox({
            id: 'sortDesc', name: 'sortDesc',
            checked: state['sortDesc'], onchange: this.handlers['changeHandler']
         });
         this.preferenceTable = this.h.table({
            className: 'preference-columns dropzone',
            id: 'preference-table',
            ondragenter: this.handlers['dragEnterHandler'],
            ondragleave: this.handlers['dragLeaveHandler'],
            ondrop: this.handlers['dropHandler']
         }, rows);
         if (this.animation) {
            const styleOptions = [];
            for (const style of ['replace', 'scroll']) {
               const option = { value: style };
               if (style == this.table['renderStyle'])
                  option.selected = 'selected';
               styleOptions.push(this.h.option(option, this.ucfirst(style)));
            }
            this.renderStyle = this.h.select({
               id: 'renderStyle', name: 'renderStyle',
               onchange: this.handlers['changeHandler']
            }, styleOptions);
         }
         return this.h.form({
            'accept-charset': 'utf-8', className: 'dialog-form',
            enctype: 'multipart/form-data', id: this.table.name + 'Prefs'
         }, [
            this.preferenceTable,
            this.h.div({ className: 'dialog-input' }, [
               this.h.label({ htmlFor: 'sortBy' }, 'Sort by\xA0'),
               this.sortBy,
               this.h.label([this.sortDesc, 'Desc'])
            ]),
            this.h.div({ className: 'dialog-input' }, [
               this.h.label({ htmlFor: 'pageSize' }, 'Show up to\xA0'),
               this.pageSize,
               this.h.span('\xA0rows')
            ]),
            this.animation ? this.h.div({ className: 'dialog-input' }, [
               this.h.label({
                  htmlFor: 'renderStyle'
               }, 'Select render style\xA0'),
               this.renderStyle
            ]) : '',
            this.renderButtons()
         ]);
      }
   }
   Object.assign(PreferenceForm.prototype, HStateTable.Util.Markup);
   class Preference {
      constructor(table, control) {
         this.table = table;
         this.rs = table.resultset;
         this.control = control;
         this.dialog;
         this.rs.extendState('tableMeta');
         this.rs.nameMap('tableMeta', 'table_meta');
         this.handlers = new PreferenceHandlers(this);
         this.form = new PreferenceForm(this);
      }
      getState() {
         const rs = this.rs;
         const state = {
            columnOrder: this.table.columns.map(col => col.name),
            download: {},
            pageSize: rs.state('pageSize'),
            renderStyle: this.table.renderStyle,
            sortColumn: rs.state('sortColumn'),
            sortDesc: rs.state('sortDesc'),
            viewable: {}
         };
         for (const column of this.table.columns) {
            state['download'][column.name] = this.isDownloadable(column.name);
            state['viewable'][column.name] = this.isViewable(column.name);
         }
         return state;
      }
      isDownloadable(columnName) {
         const column = this.table.columnIndex[columnName];
         return column && column.downloadable;
      }
      isViewable(columnName) {
         const column = this.table.columnIndex[columnName];
         return column && column.displayed;
      }
      render() {
         const close = this.control.dialogClose;
         const attr  = { className: 'dialog-close' };
         const isURL = close.match(/:/) ? true : false;
         if (!isURL) attr.className = 'dialog-close text';
         const label = isURL ? this.h.img({ src: close }) : close;
         const dialog = this.h.div({ className: 'preference-dialog' }, [
            this.h.div({
               className: 'dialog-title',
               onclick: this.control.dialogHandler
            }, [
               this.h.span({
                  className: 'dialog-title-text'
               }, this.control.dialogTitle),
               this.h.span(attr, label)
            ]),
            this.form.render(this.getState())
         ]);
         if (this.control.controlLocation.match(/Right/))
            dialog.classList.add('control-right');
         const container = this.table.topControl;
         this.dialog = this.display(container, 'dialog', dialog);
      }
   }
   Object.assign(Preference.prototype, HStateTable.Util.Markup);
   class ConfigControl {
      constructor(table, methods) {
         const config = table.roles['configurable'];
         this.control;
         this.dialogClose = config['dialog-close'] || 'x';
         this.dialogState = false;
         this.dialogTitle = config['dialog-title'] || '';
         this.label = config['label'] || 'V';
         this.location = config['location'];
         this.controlLocation = this.location['control'];
         this.rs = table.resultset;
         this.table = table;
         this.url = new URL(config['url']);
         this.dialogHandler = function(event) {
            event.preventDefault();
            this.dialogState = !this.dialogState;
            if (this.dialogState) this.preference.render();
            else this.preference.dialog.remove();
         }.bind(this);
         this.preference = new Preference(table, this);
         this.table.setControlState(this.controlLocation);
         const name = 'render' + this.controlLocation + 'Control';
         methods[name] = function(orig) {
            const container = orig();
            this.configControl.render(container);
            return container;
         };
         methods['prepareURL'] = function(orig, args) {
            args ||= {};
            const url = orig(args);
            const params = url.searchParams;
            const colName = this.rs.nameMap('tableMeta');
            const tableMeta = args['tableMeta'] || this.rs.state('tableMeta');
            if (tableMeta) params.set(colName, tableMeta);
            else params.delete(colName);
            return url;
         }.bind(this);
      }
      render(container) {
         const attr  = { className: 'preference-control' };
         const isURL = this.label.match(/:/) ? true : false;
         if (!isURL) attr.className = 'preference-control text';
         const label = isURL ? this.h.img({ src: this.label }) : this.label;
         const control = this.h.a({
            className: 'preference-link',
            onclick: this.dialogHandler,
            title: this.dialogTitle
         }, this.h.span(attr, label));
         this.control = this.display(container, 'control', control);
      }
   }
   Object.assign(ConfigControl.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.configControl = new ConfigControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Downloadable
HStateTable.Role.Downloadable = (function() {
   class Downloader {
      constructor(label) {
         this.label = label || '';
         this.textFile;
      }
      async createLink(url, defaultFilename) {
         const options = { response: 'blob' };
         const { blob, filename } = await this.bitch.sucks(url, options);
         this.textFile = window.URL.createObjectURL(blob);
         const attr = {
            className: 'state-table file-download-link',
            download: filename || defaultFilename,
            href: this.textFile
         };
         const link = this.h.a(attr, this.label);
         document.body.appendChild(link);
         return link;
      }
      clickLink(link) {
         setTimeout(function() {
            const event = new MouseEvent('click');
            link.dispatchEvent(event);
            document.body.removeChild(link);
            window.URL.revokeObjectURL(this.textFile);
         }.bind(this), 100);
      }
      async handler(url, filename) {
         this.clickLink(await this.createLink(url, filename));
      }
   }
   Object.assign(Downloader.prototype, HStateTable.Util.Markup); // Apply role
   class DownloadControl {
      constructor(table, methods) {
         this.table       = table;
         this.rs          = table.resultset;
         const config     = table.roles['downloadable'];
         this.displayLink = config['display'];
         this.filename    = config['filename'];
         this.label       = config['label'];
         this.location    = config['location'];
         this.method      = config['method'];
         this.downloader  = new Downloader(config['indicator']);
         this.controlLocation = this.location['control'];
         this.control;
         this.rs.extendState('download', false);
         this.rs.nameMap('download', 'download');
         this.downloadHandler = function(event) {
            event.preventDefault();
            const url = this.table.prepareURL({ download: this.method });
            this.downloader.handler(url, this.filename);
         }.bind(this);
         this.table.setControlState(this.controlLocation);
         const name = 'render' + this.controlLocation + 'Control';
         methods[name] = function(orig) {
            const container = orig();
            this.render(container);
            return container;
         }.bind(this);
         methods['prepareURL'] = function(orig, args) {
            args ||= {};
            const url = orig(args);
            const params = url.searchParams;
            const download = args['download'] || this.rs.state('download');
            const colName = this.rs.nameMap('download');
            if (download) {
               params.set(colName, download);
               params.delete(this.rs.nameMap('page'));
               params.delete(this.rs.nameMap('pageSize'));
            }
            else params.delete(colName);
            return url;
         }.bind(this);
      }
      render(container) {
         const control = this.displayLink ? this.h.a({
            className: 'download-link', onclick: this.downloadHandler
         }, [
            this.h.span({ className: 'sprite sprite-download' }), this.label
         ]) : this.h.span();
         this.control = this.display(container, 'control', control);
      }
   }
   Object.assign(DownloadControl.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.downloadControl = new DownloadControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Filterable
HStateTable.Role.Filterable = (function() {
   class FilterControl {
      constructor(table, methods) {
         const config = table.roles['filterable'];
         this.dialogTitle = config['dialog-title'];
         this.label = config['label'];
         this.location = config['location'];
         this.messageLabel = config['message-label'];
         this.messages;
         this.ns = HStateTable.ColumnTrait;
         this.removeLabel = config['remove-label'];
         this.table = table;
         this.rs = table.resultset;
         this.rs.extendState('filterColumn');
         this.rs.nameMap('filterColumn', 'filter_column');
         this.rs.extendState('filterValue');
         this.rs.nameMap('filterValue', 'filter_value');
         methods['createColumn'] = function(orig, table, config) {
            const column = orig(table, config);
            if (column.filterable) {
               const args = { dialogTitle: this.dialogTitle, label: this.label};
               this.applyTraits(column, this.ns, ['Filterable'], args);
            }
            return column;
         }.bind(this);
         const messages = 'render' + this.location['messages'] + 'Control';
         methods[messages] = function(orig) {
            const container = orig();
            this.renderMessages(container);
            return container;
         }.bind(this);
         methods['prepareURL'] = function(orig, args) {
            args ||= {};
            const filterColumn = this.rs.state('filterColumn');
            const filterValue = this.rs.state('filterValue');
            const colName = this.rs.nameMap('filterColumn');
            const valName = this.rs.nameMap('filterValue');
            if (filterColumn && filterValue) this.rs.state('page', 1);
            const url = orig(args);
            const params = url.searchParams;
            if (filterColumn && filterValue) {
               params.set(colName, filterColumn);
               params.set(valName, filterValue);
            }
            else {
               params.delete(colName);
               params.delete(valName);
            }
            const columnValues = args['filterColumnValues']
                  || this.rs.state('filterColumnValues');
            const colValuesName = this.rs.nameMap('filterColumnValues');
            if (columnValues) {
               params.set(colValuesName, columnValues);
               params.delete(this.rs.nameMap('page'));
               params.delete(this.rs.nameMap('pageSize'));
               params.delete(this.rs.nameMap('sortColumn'));
               params.delete(this.rs.nameMap('sortDesc'));
            }
            else { params.delete(colValuesName) }
            return url;
         }.bind(this);
      }
      renderMessages(container) {
         const messages = this.h.div();
         const column = this.rs.state('filterColumn');
         if (column && this.rs.state('filterValue')) {
            const handler = function(event) {
               event.preventDefault();
               this.rs.search({ filterColumn: '', filterValue: '' }).redraw();
            }.bind(this);
            messages.className = 'status-messages';
            messages.append(this.h.span({ className: 'filter-message' }, [
               this.messageLabel + '\xA0',
               this.h.strong('"' + this.table.columnIndex[column].label + '"'),
               '\xA0',
               this.h.a({ onclick: handler }, this.removeLabel)
            ]));
         }
         this.messages = this.display(container, 'messages', messages);
      }
   }
   Object.assign(FilterControl.prototype, HStateTable.Util.Markup);
   Object.assign(FilterControl.prototype, HStateTable.Util.Modifiers);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.filterControl = new FilterControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Form
HStateTable.Role.Form = (function() {
   class FormControl {
      constructor(table, methods) {
         this.table        = table;
         this.pageManager  = table.pageManager;
         this.rs           = table.resultset;
         const config      = table.roles['form'];
         this.buttonConfig = config['buttons'];
         this.confirm      = config['confirm'];
         this.location     = config['location'];
         this.url          = new URL(config['url']);
         this.buttons      = {};
         this.handlers     = {};
         this.form;
         this.control = 'render' + this.location['control'] + 'Control';
         this.table.setControlState(this.control);
         for (const buttonConfig of this.buttonConfig) {
            if (buttonConfig['method'] == 'get') continue;
            this.handlers[buttonConfig['action']] = function(event) {
               event.preventDefault();
               if (!confirm(this.confirm.replace(/\*/, buttonConfig['value'])))
                  return;
               this.sendForm(buttonConfig);
            }.bind(this);
         }
         methods['orderedContent'] = function(orig) {
            this.form = this.h.form({ className: 'table-form' }, orig());
            return this.form;
         }.bind(this);
         methods[this.control] = function(orig) {
            const container = orig();
            this.render(container);
            return container;
         }.bind(this);
      }
      anyChecked(buttonConfig) {
         for (const column of this.table.columns) {
            if (!Object.keys(column.rowSelector).length) continue;
            for (const box of Object.values(column.rowSelector)) {
               if (box.checked) return true;
            }
         }
         return false;
      }
      formData(buttonConfig) {
         const selector = [];
         for (const column of this.table.columns) {
            if (!Object.keys(column.rowSelector).length) continue;
            for (const box of Object.values(column.rowSelector)) {
               if (box.checked) selector.push(box.value);
            }
            break;
         }
         return { action: buttonConfig['action'], selector: selector };
      }
      isDisabled(buttonConfig) {
         if (buttonConfig['selection'] == 'disable_on_select')
            return this.anyChecked(buttonConfig);
         if (buttonConfig['selection'] == 'select_one')
            return !this.onlyOneChecked(buttonConfig);
         return !this.anyChecked(buttonConfig);
      }
      onlyOneChecked(buttonConfig) {
         for (const column of this.table.columns) {
            if (!Object.keys(column.rowSelector).length) continue;
            let count = 0;
            for (const box of Object.values(column.rowSelector)) {
               if (box.checked) count++;
            }
            return (count == 1) ? true : false;
         }
         return false;
      }
      render(container) {
         for (const buttonConfig of this.buttonConfig) {
            const action = buttonConfig['action'];
            const attr = {};
            if (this.isDisabled(buttonConfig)) attr.disabled = true;
            let control;
            if (this.handlers[action]) {
               attr.onclick = this.handlers[action];
               control = this.h.button(attr, buttonConfig['value']);
            }
            else {
               attr.href = action;
               control = this.h.a(attr, buttonConfig['value']);
               control.classList.add('table-button');
            }
            const old = this.buttons[action];
            if (old && container.contains(old))
               container.replaceChild(control, old);
            else container.append(control);
            this.buttons[action] = control;
         }
      }
      async sendForm(buttonConfig) {
         const action  = buttonConfig['action'];
         const manager = this.pageManager;
         const token   = this.rs.token;
         if (!action.match(/:/)) {
            const data = { data: this.formData(buttonConfig), _verify: token };
            const { location, object } = await this.bitch.blows(
               this.url, { json: JSON.stringify(data) }
            );
            if (manager && location) manager.renderMessage(location);
            this.rs.redraw();
         }
         else {
            const attr = { name: '_verify', value: token };
            const form = this.h.form(this.h.hidden(attr));
            const { location, text } = await this.bitch.blows(
               action, { headers: { prefer: 'render=partial' }, form: form }
            );
            if (manager && location) {
               manager.renderMessage(location);
               manager.renderLocation(location);
            }
            else if (text) {
               console.warn('Unexpected text response');
            }
         }
      }
   }
   Object.assign(FormControl.prototype, HStateTable.Util.Markup);
   Object.assign(FormControl.prototype, HStateTable.Util.Modifiers);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.formControl = new FormControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.HighlightRow
HStateTable.Role.HighlightRow = (function() {
   class HighlightRow {
      constructor(table, methods) {
         this.table = table;
         this.table.rowTraits['highlightRow'] = {};
      }
   }
   Object.assign(HighlightRow.prototype, HStateTable.Util.Modifiers);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.highlightRow = new HighlightRow(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Pageable
HStateTable.Role.Pageable = (function() {
   class PageControl {
      constructor(table, methods) {
         const config = table.roles['pageable'];
         this.className = 'page-control';
         this.enablePaging = table.properties['enable-paging'];
         this.list = this.h.ul();
         this.list.className = this.className;
         this.location = config['location'];
         this.pagingText = 'Page %current_page of %last_page';
         this.rs = table.resultset;
         this.table = table;
         this.table.setControlState(this.location['control']);
         const messages = 'render' + this.location['control'] + 'Control';
         methods[messages] = function(orig) {
            const container = orig();
            this.pageControl.render(container);
            return container;
         };
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
         let pages = this.rs.rowCount / this.rs.state('pageSize');
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
               item = this.h.li({
                  className: 'page-indicator'
               }, this.interpolatePageText());
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
         this.list = this.display(container, 'list', list);
      }
      renderPageControlNoCount(container) {
         const currentPage = this.rs.state('page');
         const atFirst = !!(currentPage <= this.firstPage());
         const atLast  = !!(currentPage >= this.table.rowCount);
         const list = this.h.ul({ className: this.className });
         for (const text of ['first', 'prev', 'page', 'next']) {
            let item;
            if (text == 'page') {
               item = this.h.li({
                  className: 'page-indicator'
               }, 'Page\xA0' + currentPage);
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
         this.list = this.display(container, 'list', list);
      }
   }
   Object.assign(PageControl.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.pageControl = new PageControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.PageSize
HStateTable.Role.PageSize = (function() {
   class PageSizeControl {
      constructor(table, methods) {
         const config = table.roles['pagesize'];
         this.className = 'page-size-control';
         this.enablePaging = table.properties['enable-paging'];
         this.list = this.h.ul();
         this.list.className = this.className;
         this.location = config['location'];
         this.rs = table.resultset;
         this.table = table;
         this.table.setControlState(this.location['control']);
         const messages = 'render' + this.location['control'] + 'Control';
         methods[messages] = function(orig) {
            const container = orig();
            this.pageSizeControl.render(container);
            return container;
         };
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
         this.list = this.display(container, 'list', list);
      }
   }
   Object.assign(PageSizeControl.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.pageSizeControl = new PageSizeControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Reorderable
HStateTable.Role.Reorderable = (function() {
   class OrderControl {
      constructor(table, methods) {
         const config = table.roles['reorderable'];
         this.table = table;
         this.label = config['label'] || '+';
         this.title = config['title'] || '';
      }
   }
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.orderControl = new OrderControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Searchable
HStateTable.Role.Searchable = (function() {
   class SearchControl {
      constructor(table, methods) {
         const config = table.roles['searchable'];
         this.table = table;
         this.location = config['location'];
         this.messageAll = config['message-all'];
         this.messageLabel = config['message-label'];
         this.placeholder = config['placeholder'];
         this.removeLabel = config['remove-label'];
         this.control;
         this.messages;
         this.searchableColumns = [];
         this.rs = table.resultset;
         this.rs.extendState('searchColumn');
         this.rs.nameMap('searchColumn', 'search_column');
         this.rs.extendState('searchValue');
         this.rs.nameMap('searchValue', 'search');
         for (const columnName of config['searchable-columns']) {
            const column = this.table.columnIndex[columnName];
            if (column) this.searchableColumns.push(column);
         }
         const search = 'render' + this.location['control'] + 'Control';
         this.table.setControlState(search);
         methods[search] = function(orig) {
            const container = orig();
            this.renderSearch(container);
            return container;
         }.bind(this);
         const messages = 'render' + this.location['messages'] + 'Control';
         methods[messages] = function(orig) {
            const container = orig();
            this.renderMessages(container);
            return container;
         }.bind(this);
         methods['prepareURL'] = function(orig, args) {
            args ||= {};
            const searchValue = this.rs.state('searchValue');
            const colName = this.rs.nameMap('searchColumn');
            const valName = this.rs.nameMap('searchValue');
            if (searchValue) this.rs.state('page', 1);
            const url = orig(args);
            const params = url.searchParams;
            if (searchValue) {
               const searchColumn = this.rs.state('searchColumn');
               if (searchColumn) params.set(colName, searchColumn);
               else params.delete(colName);
               params.set(valName, searchValue);
            }
            else {
               params.delete(colName);
               params.delete(valName);
            }
            return url;
         }.bind(this);
      }
      searchAction(text) {
         return this.h.span({ className: 'search-button' },this.h.button(text));
      }
      searchHidden(selectElements) {
         const hidden = this.h.span({ className: 'search-hidden'});
         for (const select of selectElements) { hidden.append(select) }
         return hidden;
      }
      searchInput() {
         return this.h.text({
            className: 'search-field',
            name: this.rs.nameMap('searchValue'),
            placeholder: this.placeholder,
            size: 10,
            value: this.rs.state('searchValue') || ''
         });
      }
      searchSelect(selectElements) {
         if (!this.searchableColumns.length) return;
         const options = [];
         const searchColumn = this.rs.state('searchColumn') || '';
         let selectPrefix = 'All';
         for (const column of this.searchableColumns) {
            let selected = false;
            if (searchColumn && searchColumn == column.name) {
               selected = true;
               selectPrefix = column.label;
            }
            const attr = { className: 'search-select', value: column.name };
            if (selected) attr['selected'] = 'selected';
            options.push(this.h.option(attr, column.label));
         }
         selectElements.push(this.h.span({ className: 'search-arrow' }));
         const select = this.h.select({
            className: 'search-select', name: this.rs.nameMap('searchColumn')
         }, this.h.option({ className: 'search-select', value: '' }, 'All'));
         for (const anOption of options) { select.append(anOption) }
         selectElements.push(select);
         return select;
      }
      renderSearch(container) {
         const selectElements = [];
         const select = this.searchSelect(selectElements);
         const input = this.searchInput();
         const wrapper = this.h.span({ className: 'search-wrapper' }, [
            this.searchHidden(selectElements),
            input,
            this.searchAction('Search')
         ]);
         const handler = function(event) {
            event.preventDefault();
            if (!input.value) return;
            const column = select ? select.value : '';
            const attr = { 'searchColumn': column, 'searchValue': input.value };
            this.rs.search(attr).redraw();
         }.bind(this);
         const control = this.h.form({
            className: 'search-box', method: 'get', onsubmit: handler
         }, wrapper);
         control.setAttribute('listener', true);
         this.control = this.display(container, 'control', control);
      }
      renderMessages(container) {
         const rs = this.rs;
         const searchCol = rs.state('searchColumn');
         const column = this.table.columnIndex[searchCol];
         const value = rs.state('searchValue');
         const messages = this.h.div();
         if (value) {
            const handler = function(event) {
               event.preventDefault();
               rs.search({ searchColumn: '', searchValue: '' }).redraw();
            }.bind(this);
            const label = column ? column.label
                   : ( searchCol ? this.ucfirst(searchCol) : this.messageAll);
            messages.className = 'status-messages';
            messages.append(this.h.span({ className: 'search-message' }, [
               this.messageLabel + '\xA0',
               this.h.strong('"' + value + '"'), '\xA0in\xA0',
               this.h.strong('"' + label + '"'),
               this.h.a({ onclick: handler }, this.removeLabel)
            ]));
         }
         this.messages = this.display(container, 'messages', messages);
      }
   }
   Object.assign(SearchControl.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.searchControl = new SearchControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Tagable
HStateTable.Role.Tagable = (function() {
   class TagControl {
      constructor(table, methods) {
         this.table         = table;
         this.rs            = table.resultset;
         const config       = table.roles['tagable'];
         this.appendTo      = config['append-to'];
         this.enablePopular = config['enable-popular'];
         this.location      = config['location']['control'];
         this.searchColumn  = config['search-column'];
         this.section       = config['section'];
         this.tagColumn     = config['tag-column'];
         this.tags          = config['tags'];
         this.control;
         this.prevTag = '_initial_';
         this.handler = function(tag) {
            const attr = { searchColumn: this.searchColumn, searchValue: tag };
            return function(event) {
               event.preventDefault();
               this.rs.search(attr).redraw();
            }.bind(this);
         }.bind(this);
         if (this.appendTo) {
            this.table.columnIndex[this.appendTo].cellTraits.push('Tagable');
            return;
         }
         if (this.section) {
            methods['redraw'] = function(orig) {
               this.prevTag = '_initial_';
               orig();
            }.bind(this);
            methods['renderRow'] = function(orig, container, row, className) {
               const tag = row.result[this.searchColumn];
               if (this.prevTag != (tag || ''))
                  container.append(this.renderSection(tag));
               return orig(container, row, className);
            }.bind(this);
            return;
         }
         const content = this.h.ul({ className: 'cell-content-append' });
         for (const tag of this.tags) {
            const arrow = this.h.span({ className: 'tag-arrow-left' });
            const value = this.h.span({
               className: 'tag-value', onclick: this.handler(tag)
            }, tag);
            content.append(
               this.h.li({ className: 'cell-tag' }, [arrow, value])
            );
         }
         const location = 'render' + this.location + 'Control';
         this.table.setControlState(location);
         methods[location] = function(orig) {
            const container = orig();
            const control = this.h.div({ className: 'tag-control' }, content);
            this.control = this.display(container, 'control', control);
            return container;
         }.bind(this);
      }
      renderSection(tag) {
         const cells = [];
         let colSpan = this.table.columns.length - 1;
         if (this.table.columns[0].options['checkall']) {
            cells.push(this.h.td({ className: 'section-check' }, ' '));
            colSpan--;
         }
         const label = tag ? tag.replace(/\|/g, ' + ') : '\xA0';
         cells.push(this.h.td({
            className: 'section-tag', colSpan: colSpan
         }, this.h.span({
            className: 'tag-value', onclick: this.handler(tag)
         }, label)));
         this.prevTag = tag ? tag : '';
         return this.h.tr({ className: 'section-row' }, cells);
      }
   }
   Object.assign(TagControl.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         HStateTable.Util.Modifiers.resetModifiers(modifiedMethods);
         this.tagControl = new TagControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
