// Package HStateTable.Role.Active
HStateTable.Role.Active = (function() {
   class Active {
      constructor(table, methods) {
         const config = table.roles['active'];
         this.activeForm;
         this.enabled = config['enabled'];
         this.label = config['label'];
         this.location = config['location'];
         this.controlLocation = this.location['control'];
         this.rs = table.resultset;
         this.showInactive = false;
         this.table = table;
         this.table.rowTraits['active'] = {};
         this.rs.extendState('showInactive', false);
         this.rs.nameMap('showInactive', 'show_inactive');
         this.handler = function(event) {
            this.showInactive = !this.showInactive;
            this.rs.search({ showInactive: this.showInactive }).redraw();
         }.bind(this);
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
         this.active = new Active(this, modifiedMethods);
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
            const display = this.h.div(attr, this.h.figure(
               { className: 'highcharts-figure' },
               this.h.div({ id: 'chartable' })
            ));
            if (location == 'Top' || location == 'Left')
               content.unshift(display);
            else content.push(display);
            orig(container, content);
         }.bind(this);
         methods['renderRows'] = function(orig){ this.render(orig) }.bind(this);
      }
      async render(orig) {
         await orig();
         const state = this.rs.getState(this.stateAttr);
         if (!this.previousState) this.previousState = state;
         else if (!this.rs.stateChanged(this.previousState)) return;
         this.previousState = state;
         const enablePaging = this.rs.enablePaging;
         this.rs.enablePaging = false;
         const url = this.table.prepareURL();
         this.rs.enablePaging = enablePaging;
         const response = await this.rs.fetchJSON(url);
         const results = response['records'];
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
         Highcharts.chart('chartable', config);
      }
   }
   Object.assign(Chartable.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
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
         await this.rs.storeJSON(this.control.url, '');
         const url = this.table.prepareURL({ tableMeta: true });
         const response = await this.rs.fetchJSON(url);
         const order = response['column-order'];
         if (order) this.applyColumnOrder(order);
         for (const column of this.table.columns) {
            column.displayed = response['displayed'][column.name];
            column.downloadable = response['downloadable'][column.name];
         }
         this.rs.state('pageSize',   response['page-size']);
         this.rs.state('sortColumn', response['sort-column']);
         this.rs.state('sortDesc',   response['sort-desc']);
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
         this.rs.state('sortColumn', state['sortColumn']);
         form.sortBy.value = state['sortColumn'];
         this.rs.state('sortDesc', state['sortDesc']);
         form.sortDesc.checked = state['sortDesc'];
      }
      async savePreference() {
         const data = this.updatePreference();
         const response = await this.rs.storeJSON(this.control.url, data);
         this.preference.form.initialState = this.preference.getState();
         this.rs.redraw();
      }
      updatePreference() {
         const form = this.preference.form;
         const pageSize = form.pageSize.value;
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
   class PreferenceForm {
      constructor(preference) {
         this.preference = preference;
         this.handlers = preference.handlers.functions;
         this.initialState = preference.getState();
         this.table = preference.table;
         this.downloadable = this.table.roles['downloadable'] ? true : false;
         this.reorderable = this.table.roles['reorderable'] ? true : false;
         this.downBoxes = [];
         this.initialState;
         this.pageSize;
         this.preferenceTable;
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
            }, 'Save'),
         ]);
      }
      renderCells(state, column) {
         const viewBox = this.h.checkbox({
            checked: state['viewable'][column.name],
            id: column.name + 'View', name: column.name + 'View',
            onchange: this.handlers['changeHandler']
         });
         this.viewBoxes.push(viewBox);
         const cells = [
            this.h.td(column.label || this.ucfirst(column.name)),
            this.h.td({ className: 'checkbox' }, viewBox),
         ];
         if (this.downloadable) {
            const downBox = this.h.checkbox({
               checked: state['download'][column.name],
               id: column.name + 'Down', name: column.name + 'Down',
            });
            this.downBoxes.push(downBox);
            cells.push(this.h.td({ className: 'checkbox' }, downBox));
         }
         if (this.reorderable) {
            const orderControl = this.table.orderControl;
            cells.push(this.h.td({
               className: 'grab-handle-cell'
            }, this.h.div({
               className: 'grab-handle', title: orderControl.title
            }, orderControl.label)));
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
         const dialog = this.h.div({ className: 'preference-dialog' }, [
            this.h.div({
               className: 'dialog-title',
               onclick: this.control.dialogHandler
            }, [
               this.control.dialogTitle,
               this.h.span({ className: 'dialog-close' }, 'x')
            ]),
            this.form.render(this.getState())
         ]);
         const container = this.table.topControl;
         this.dialog = this.display(container, 'dialog', dialog);
      }
   }
   Object.assign(Preference.prototype, HStateTable.Util.Markup);
   class ConfigControl {
      constructor(table, methods) {
         const config = table.roles['configurable'];
         this.control;
         this.dialogState = false;
         this.dialogTitle = config['dialog-title'] || '';
         this.label = config['label'] || 'V';
         this.location = config['location'];
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
         const name = 'render' + this.location['control'] + 'Control';
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
         const control = this.h.a({
            className: 'preference-link',
            onclick: this.dialogHandler,
            title: this.dialogTitle
         }, [
            this.h.span({ className: 'sprite sprite-preference' }),
            '\xA0' + this.label + '\xA0'
         ]);
         this.control = this.display(container, 'control', control);
      }
   }
   Object.assign(ConfigControl.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         this.configControl = new ConfigControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Downloadable
HStateTable.Role.Downloadable = (function() {
   class Downloader {
      constructor(resultset) {
         this.rs = resultset;
         this.textFile = null;
      }
      async createLink(url, fDefault) {
         const { blob, filename } = await this.rs.fetchBlob(url)
         if (this.textFile !== null) window.URL.revokeObjectURL(this.textFile);
         this.textFile = window.URL.createObjectURL(blob);
         const attr = { download: filename || fDefault, href: this.textFile };
         const link = this.h.a(attr, 'Downloading...');
         document.body.appendChild(link);
         return link;
      }
      clickLink(link) {
         setTimeout(function() {
            const event = new MouseEvent('click');
            link.dispatchEvent(event);
            document.body.removeChild(link);
         }, 100);
      }
      async handler(url, filename) {
         this.clickLink(await this.createLink(url, filename));
      }
   }
   Object.assign(Downloader.prototype, HStateTable.Util.Markup); // Apply role
   class DownloadControl {
      constructor(table, methods) {
         const config = table.roles['downloadable'];
         this.control;
         this.displayLink = config['display'];
         this.downloader = new Downloader(table.resultset);
         this.filename = config['filename'];
         this.label = config['label'];
         this.location = config['location'];
         this.method = config['method'];
         this.rs = table.resultset;
         this.table = table;
         this.rs.extendState('download', false);
         this.rs.nameMap('download', 'download');
         this.downloadHandler = function(event) {
            event.preventDefault();
            const url = this.table.prepareURL({ download: this.method });
            this.downloader.handler(url, this.filename);
            this.rs.reset();
         }.bind(this);
         const name = 'render' + this.location['control'] + 'Control';
         methods[name] = function(orig) {
            const container = orig();
            this.downloadControl.render(container);
            return container;
         };
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
            const url = orig(args);
            const params = url.searchParams;
            const filterColumn = this.rs.state('filterColumn');
            const filterValue = this.rs.state('filterValue');
            const colName = this.rs.nameMap('filterColumn');
            const valName = this.rs.nameMap('filterValue');
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
         this.filterControl = new FilterControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Form
HStateTable.Role.Form = (function() {
   class FormControl {
      constructor(table, methods) {
         const config = table.roles['form'];
         this.buttonConfig = config['buttons'];
         this.buttons = {};
         this.confirm = config['confirm'];
         this.form;
         this.handlers = {};
         this.location = config['location'];
         this.control = 'render' + this.location['control'] + 'Control';
         this.rs = table.resultset;
         this.table = table;
         this.url = new URL(config['url']);
         for (const buttonConfig of this.buttonConfig) {
            this.handlers[buttonConfig['action']] = function(event) {
               event.preventDefault();
               if (!confirm(this.confirm.replace(/\*/, buttonConfig['value'])))
                  return;
               this.postForm(buttonConfig);
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
            if (!Object.keys(column.rowSelector)) continue;
            for (const box of Object.values(column.rowSelector)) {
               if (box.checked) return true;
            }
         }
         return false;
      }
      formData(buttonConfig) {
         const selector = [];
         for (const column of this.table.columns) {
            if (!Object.keys(column.rowSelector)) continue;
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
            if (!Object.keys(column.rowSelector)) continue;
            let count = 0;
            for (const box of Object.values(column.rowSelector)) {
               if (box.checked) count++;
            }
            return (count == 1) ? true : false;
         }
         return false;
      }
      async postForm(buttonConfig) {
         const data = this.formData(buttonConfig);
         const response = await this.rs.storeJSON(this.url, data);
         console.log(response);
         this.rs.redraw();
      }
      render(container) {
         for (const buttonConfig of this.buttonConfig) {
            const action = buttonConfig['action'];
            const button = this.h.button({
               className: buttonConfig['class'],
               disabled: this.isDisabled(buttonConfig),
               onclick: this.handlers[action]
            }, buttonConfig['value']);
            if (this.buttons[action]
                && container.contains(this.buttons[action])) {
               container.replaceChild(button, this.buttons[action]);
            }
            else { container.append(button) }
            this.buttons[action] = button;
         }
      }
   }
   Object.assign(FormControl.prototype, HStateTable.Util.Markup);
   Object.assign(FormControl.prototype, HStateTable.Util.Modifiers);
   const modifiedMethods = {};
   return {
      initialise: function() {
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
         this.list = this.display(container, 'list', list);
      }
   }
   Object.assign(PageControl.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
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
         this.control;
         this.location = config['location'];
         this.messageAll = config['message-all'];
         this.messageLabel = config['message-label'];
         this.messages;
         this.placeholder = config['placeholder'];
         this.removeLabel = config['remove-label'];
         this.searchableColumns = [];
         this.table = table;
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
            const url = orig(args);
            const params = url.searchParams;
            const searchValue = this.rs.state('searchValue');
            const colName = this.rs.nameMap('searchColumn');
            const valName = this.rs.nameMap('searchValue');
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
// selectElements.push(this.h.span({ className:'search-display'},selectPrefix));
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
         this.searchControl = new SearchControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Tagable
HStateTable.Role.Tagable = (function() {
   class TagControl {
      constructor(table, methods) {
         const config = table.roles['tagable'];
         this.appendTo = config['append-to'];
         this.control;
         this.enablePopular = config['enable-popular'];
         this.location = config['location']['control'];
         this.searchColumn = config['search-column'];
         this.tags = config['tags'];
         this.table = table;
         this.rs = table.resultset;
         if (this.appendTo) {
            this.table.columnIndex[this.appendTo].cellTraits.push('Tagable');
            return;
         }
         const handler = function(tag) {
            const attr = { searchColumn: this.searchColumn, searchValue: tag };
            return function(event) {
               event.preventDefault();
               this.rs.search(attr).redraw();
            }.bind(this);
         }.bind(this);
         const content = this.h.ul({ className: 'cell-content-append' });
         for (const tag of this.tags) {
            const arrow = this.h.span({ className: 'tag-arrow-left' });
            const value = this.h.span({
               className: 'tag-value', onclick: handler(tag)
            }, tag);
            content.append(
               this.h.li({ className: 'cell-tag' }, [arrow, value])
            );
         }
         methods['render' + this.location + 'Control'] = function(orig) {
            const container = orig();
            const control = this.h.div({ className: 'tag-control' }, content);
            this.control = this.display(container, 'control', control);
            return container;
         }.bind(this);
      }
   }
   Object.assign(TagControl.prototype, HStateTable.Util.Markup);
   const modifiedMethods = {};
   return {
      initialise: function() {
         this.tagControl = new TagControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
