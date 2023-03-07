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
            this.rs.state('showInactive', this.showInactive);
            this.rs.redraw();
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
         const box = this.h.input(
            { checked: this.showInactive, name: 'showInactive',
              onclick: this.handler, type: 'checkbox' }
         );
         if (this.controlLocation.match(/Right/)) content.push(box);
         else content.unshift(box);
         const activeForm = this.h.form(
            { className: 'active-control', id: this.table.name + 'Active' },
            this.h.label(
               { className: 'active-control-label', htmlFor: 'showInactive' },
               content
            )
         );
         if (this.activeForm && container.contains(this.activeForm)) {
            container.replaceChild(activeForm, this.activeForm);
         }
         else { container.append(activeForm) }
         this.activeForm = activeForm;
      }
   }
   Object.assign(Active.prototype, HStateTable.Util.markup);
   Object.assign(Active.prototype, HStateTable.Util.modifiers);
   const modifiedMethods = {};
   return {
      initialise: function() {
         this.active = new Active(this, modifiedMethods);
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
   Object.assign(CheckAllControl.prototype, HStateTable.Util.modifiers);
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
   class Preference {
      constructor(table, control) {
         this.control = control;
         this.dialog;
         this.downBoxes = [];
         this.downloadable = table.roles['downloadable'] ? true : false;
         this.pageSize;
         this.sortBy;
         this.sortDesc;
         this.table = table;
         this.viewBoxes = [];
         this.rs = table.resultset;
         this.rs.extendState('tableMeta');
         this.rs.nameMap('tableMeta', 'table_meta');
         this.clearHandler = function(event) {
            event.preventDefault();
            this.control.dialogHandler(event);
            this.resetState();
         }.bind(this);
         this.saveHandler = function(event) {
            event.preventDefault();
            this.control.dialogHandler(event);
            this.rs.storeJSON(this.control.url, this.formData());
            this.rs.redraw();
         }.bind(this);
         this.downloadHandler = function(event) {
            event.preventDefault();
            this.control.dialogHandler(event);
            this.table.downloadControl.downloadHandler(event);
         }.bind(this);
      }
      formData() {
         this.rs.search({
            pageSize: this.pageSize.value,
            sortColumn: this.sortBy.value,
            sortDesc: this.sortDesc.checked
         });
         const data = {
            columns: {},
            "page_size": this.pageSize.value,
            sort: {
               column: this.sortBy.value,
               desc: this.sortDesc.checked
            }
         };
         for (const box of this.downBoxes) {
            const name = box.name.replace(/Down$/, '');
            data.columns[name] ||= {};
            data.columns[name]['download'] = box.checked;
            this.table.findColumn(name)['downloadable'] = box.checked;
         }
         for (const box of this.viewBoxes) {
            const name = box.name.replace(/View$/, '');
            data.columns[name] ||= {};
            data.columns[name]['view'] = box.checked;
            this.table.findColumn(name)['displayed'] = box.checked;
         }
         return data;
      }
      isViewable(columnName) {
         const column = this.table.findColumn(columnName);
         return column && column.displayed;
      }
      isDownloadable(columnName) {
         const column = this.table.findColumn(columnName);
         return column && column.downloadable;
      }
      renderButtons () {
         return this.h.div({ className: 'dialog-input dialog-buttons' }, [
            this.downloadable
               ? this.h.button({ className: 'dialog-button-download',
                                 onclick: this.downloadHandler,
                                 type: 'submit' }, 'Download') : '',
            this.h.button({ className: 'dialog-button-clear',
                            onclick: this.clearHandler,
                            type: 'submit' }, 'Clear'),
            this.h.button({ className: 'dialog-button-reset',
                            type: 'reset'  }, 'Reset'),
            this.h.button({ className: 'dialog-button-save',
                            onclick: this.saveHandler,
                            type: 'submit' }, 'Save'),
         ]);
      }
      renderCells(column) {
         const viewBox = this.h.input({
            checked: this.isViewable(column.name), id: column.name + 'View',
            name: column.name + 'View', type: 'checkbox'
         });
         this.viewBoxes.push(viewBox);
         const cells = [
            this.h.td(column.label || this.ucfirst(column.name)),
            this.h.td({ className: 'checkbox' }, viewBox),
         ];
         if (this.downloadable) {
            const downBox = this.h.input({
               checked: this.isDownloadable(column.name),
               id: column.name + 'Down', name: column.name + 'Down',
               type: 'checkbox'
            });
            this.downBoxes.push(downBox);
            cells.push(this.h.td({ className: 'checkbox' }, downBox));
         }
         return cells;
      }
      renderForm() {
         this.downBoxes = [];
         this.viewBoxes = [];
         const rows = [this.h.tr([
            this.h.th('Column'),
            this.h.th('View'),
            this.downloadable ? this.h.th('Download') : ''
         ])];
         const sortOptions = [ this.h.option({ value: '' }, '[ Default ]') ];
         for (const column of this.table.columns) {
            if (!column.cellTraits.includes('Checkbox'))
               rows.push(this.h.tr(this.renderCells(column)));
            if (column.sortable) {
               const option = { value: column.name };
               if (column.name == this.rs.state('sortColumn'))
                  option.selected = 'selected';
               sortOptions.push(this.h.option(option, column.label));
            }
         }
         const sizeOptions = [];
         for (const size of [10, 20, 50, 100]) {
            const option = { value: size };
            if (size == this.rs.state('pageSize')) option.selected = 'selected';
            sizeOptions.push(this.h.option(option, size));
         }
         this.pageSize = this.h.select(
            { id: 'pageSize', name: 'pageSize' }, sizeOptions
         );
         this.sortBy = this.h.select(
            { id: 'sortBy', name: 'sortBy' }, sortOptions
         );
         this.sortDesc = this.h.input(
            { id: 'sortDesc', checked: this.rs.state('sortDesc'),
              name: 'sortDesc', type: 'checkbox' }
         );
         return this.h.form({
            'accept-charset': 'utf-8', className: 'dialog-form',
            enctype: 'multipart/form-data', id: this.table.name + 'Prefs'
         }, [
            this.h.table({ className: 'preference-columns' }, rows),
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
      render() {
         this.dialog = this.h.div({ className: 'preference-dialog' }, [
            this.h.div(
               { className: 'dialog-title',
                 onclick: this.control.dialogHandler },
               this.h.span({ className: 'dialog-close' }, 'x')
            ),
            this.renderForm()
         ]);
         this.table.topControl.append(this.dialog);
      }
      async resetState() {
         await this.rs.storeJSON(this.control.url, '');
         const url = this.table.prepareURL({ tableMeta: true });
         const response = await this.rs.fetchJSON(url);
         for (const column of this.table.columns) {
            column.displayed = response['displayed'][column.name];
            column.downloadable = response['downloadable'][column.name];
         }
         this.rs.state('pageSize', response['page-size']);
         this.rs.state('sortColumn', response['sort-column']);
         this.rs.state('sortDesc', response['sort-desc']);
         this.rs.redraw();
      }
   }
   Object.assign(Preference.prototype, HStateTable.Util.markup);
   class ConfigControl {
      constructor(table, methods) {
         const config = table.roles['configurable'];
         this.control;
         this.dialogState = false;
         this.label = config['label'] || 'V';
         this.location = config['location'];
         this.rs = table.resultset;
         this.table = table;
         this.url = new URL(config['url'].replace(/\*/, table.name));
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
         const control = this.h.a(
            { className: 'preference-link', onclick: this.dialogHandler,
              title: 'Preferences'
            },
            [ this.h.span({ className: 'sprite sprite-preference' }),
              '\xA0' + this.label + '\xA0' ]
         );
         if (this.control && container.contains(this.control)) {
            container.replaceChild(control, this.control);
         }
         else { container.append(control) }
         this.control = control;
      }
   }
   Object.assign(ConfigControl.prototype, HStateTable.Util.markup);
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
   Object.assign(Downloader.prototype, HStateTable.Util.markup); // Apply role
   class DownloadControl {
      constructor(table, methods) {
         const config = table.roles['downloadable'];
         this.control;
         this.display = config['display'];
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
         const control = this.display ? this.h.a(
            { className: 'download-link', onclick: this.downloadHandler },
            [ this.h.span({ className: 'sprite sprite-download' }), this.label ]
         ) : this.h.span();
         if (this.control && container.contains(this.control)) {
            container.replaceChild(control, this.control);
         }
         else { container.append(control) }
         this.control = control;
      }
   }
   Object.assign(DownloadControl.prototype, HStateTable.Util.markup);
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
         this.label = config['label'];
         this.location = config['location'];
         this.messages;
         this.ns = HStateTable.ColumnTrait;
         this.table = table;
         this.rs = table.resultset;
         this.rs.extendState('filterColumn');
         this.rs.nameMap('filterColumn', 'filter_column');
         this.rs.extendState('filterValue');
         this.rs.nameMap('filterValue', 'filter_value');
         methods['createColumn'] = function(orig, table, config) {
            const column = orig(table, config);
            if (column.filterable) {
               const args = { label: this.label };
               this.applyTraits(column, this.ns, ['Filterable'], args);
            }
            return column;
         }.bind(this);
         const messages = 'render' + this.location['messages'] + 'Control';
         methods[messages] = function(orig) {
            const container = orig();
            this.filterControl.renderMessages(container);
            return container;
         };
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
               this.rs.search({ filterColumn: null, filterValue: null });
               this.rs.redraw();
            }.bind(this);
            messages.className = 'status-messages';
            messages.append(this.h.span({ className: 'filter-message' }, [
               'Filtering on column\xA0',
               this.h.strong('"' + this.table.findColumn(column).label + '"'),
               '\xA0',
               this.h.a({ onclick: handler }, 'Show all')
            ]));
         }
         if (this.messages && container.contains(this.messages)) {
            container.replaceChild(messages, this.messages);
         }
         else { container.append(messages) }
         this.messages = messages;
      }
   }
   Object.assign(FilterControl.prototype, HStateTable.Util.markup);
   Object.assign(FilterControl.prototype, HStateTable.Util.modifiers);
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
         this.handlers = {};
         this.location = config['location'];
         this.control = 'render' + this.location['control'] + 'Control';
         this.rs = table.resultset;
         this.table = table;
         this.url = config['url'];
         for (const buttonConfig of this.buttonConfig) {
            this.handlers[buttonConfig['action']] = function(event) {
               event.preventDefault();
               if (!confirm(this.confirm.replace(/\*/, buttonConfig['value'])))
                  return;
               this.postForm(buttonConfig);
            }.bind(this);
         }
         methods['appendContainer'] = function(orig, container, content) {
            const form = this.h.form({ className: 'table-form' });
            orig(form, content);
            container.append(form);
         };
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
      is_disabled(buttonConfig) {
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
         await this.rs.storeJSON(this.url, this.formData(buttonConfig));
         this.rs.redraw();
      }
      render(container) {
         for (const buttonConfig of this.buttonConfig) {
            const action = buttonConfig['action'];
            const button = this.h.button(
               { className: buttonConfig['class'],
                 disabled: this.is_disabled(buttonConfig),
                 onclick: this.handlers[action],
                 type: 'submit' }, buttonConfig['value']
            );
            if (this.buttons[action]
                && container.contains(this.buttons[action])) {
               container.replaceChild(button, this.buttons[action]);
            }
            else { container.append(button) }
            this.buttons[action] = button;
         }
      }
   }
   Object.assign(FormControl.prototype, HStateTable.Util.markup);
   Object.assign(FormControl.prototype, HStateTable.Util.modifiers);
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
   Object.assign(HighlightRow.prototype, HStateTable.Util.modifiers);
   const modifiedMethods = {};
   return {
      initialise: function() {
         this.highlightRow = new HighlightRow(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
// Package HStateTable.Role.Searchable
HStateTable.Role.Searchable = (function() {
   class SearchControl {
      constructor(table, methods) {
         const config = table.roles['searchable'];
         this.location = config['location'];
         this.messages;
         this.searchControl;
         this.searchableColumns = [];
         this.table = table;
         this.rs = table.resultset;
         this.rs.extendState('searchColumn');
         this.rs.nameMap('searchColumn', 'search_column');
         this.rs.extendState('searchValue');
         this.rs.nameMap('searchValue', 'search');
         for (const columnName of config['searchable_columns']) {
            const column = this.table.findColumn(columnName);
            if (column) this.searchableColumns.push(column);
         }
         const search = 'render' + this.location['control'] + 'Control';
         methods[search] = function(orig) {
            const container = orig();
            this.searchControl.renderSearch(container);
            return container;
         };
         const messages = 'render' + this.location['messages'] + 'Control';
         methods[messages] = function(orig) {
            const container = orig();
            this.searchControl.renderMessages(container);
            return container;
         };
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
         return this.h.span(
            { className: 'search-button' },
            this.h.button({ type: 'submit' }, text)
         );
      }
      searchHidden(selectElements) {
         const hidden = this.h.span({ className: 'search-hidden'});
         for (const select of selectElements) { hidden.append(select) }
         return hidden;
      }
      searchInput() {
         return this.h.input({
            className: 'search-field',
            name: this.rs.nameMap('searchValue'),
            placeholder: 'Search table...',
            size: 10,
            type: 'text',
            value: this.rs.state('searchValue') || null
         });
      }
      searchSelect(selectElements) {
         if (!this.searchableColumns.length) return;
         const options = [];
         const searchColumn = this.rs.state('searchColumn') || null;
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
            this.rs.search({
               'searchColumn': select ? select.value : '',
               'searchValue': input.value
            }).redraw();
         }.bind(this);
         const control = this.h.form({
            className: 'search-box', method: 'get', onsubmit: handler
         }, wrapper);
         if (this.searchControl && container.contains(this.searchControl)) {
            container.replaceChild(control, this.searchControl);
         }
         else { container.append(control) }
         this.searchControl = control;
      }
      renderMessages(container) {
         const rs = this.rs;
         const searchCol = rs.state('searchColumn');
         const column = this.table.findColumn(searchCol);
         const value = rs.state('searchValue');
         const messages = this.h.div();
         if (value) {
            const handler = function(event) {
               event.preventDefault();
               rs.search({ searchColumn: null, searchValue: null }).redraw();
            }.bind(this);
            const label = column ? column.label
                   : ( searchCol ? this.ucfirst(searchCol) : 'All Columns');
            messages.className = 'status-messages';
            messages.append(this.h.span({ className: 'search-message' }, [
               'Searching for\xA0',
               this.h.strong('"' + value + '"'), '\xA0in\xA0',
               this.h.strong('"' + label + '"'),
               this.h.a({ onclick: handler }, 'Show all')
            ]));
         }
         if (this.messages && container.contains(this.messages)) {
            container.replaceChild(messages, this.messages);
         }
         else { container.append(messages) }
         this.messages = messages;
      }
   }
   Object.assign(SearchControl.prototype, HStateTable.Util.markup);
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
         this.appendTo = config['append_to'];
         this.enablePopular = config['enable_popular'];
         this.location = config['location'];
         this.searchColumn = config['search_column'];
         this.table = table;
         this.tags = config['tags'];
         const column = this.table.findColumn(this.appendTo);
         column.cellTraits.push('Tagable');
      }
   }
   const modifiedMethods = {};
   return {
      initialise: function() {
         this.tagControl = new TagControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
