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
         this.clearHandler = function(event) {
            event.preventDefault();
            this.resetState();
            this.storeJSON(this.control.url, '');
            this.control.dialogHandler(event);
            this.table.redraw();
         }.bind(this);
         this.saveHandler = function(event) {
            event.preventDefault();
            this.storeJSON(this.control.url, this.formData());
            this.control.dialogHandler(event);
            this.table.redraw();
         }.bind(this);
         this.downloadHandler = function(event) {
            event.preventDefault();
            this.table.downloadControl.downloadHandler(event);
            this.control.dialogHandler(event);
         }.bind(this);
      }
      resetState() {
         this.table.resultset.search({
            pageSize: this.table.properties['page-size'],
            sortColumn: this.table.properties['sort-column'],
            sortDesc: this.table.properties['sort-desc']
         });
         // TODO: Reset the column displayed/downloadable attr
      }
      formData() {
         this.table.resultset.search({
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
            this.findColumn(name)['downloadable'] = box.checked;
         }
         for (const box of this.viewBoxes) {
            const name = box.name.replace(/View$/, '');
            data.columns[name] ||= {};
            data.columns[name]['view'] = box.checked;
            this.findColumn(name)['displayed'] = box.checked;
         }
         return data;
      }
      findColumn(columnName) {
         for (const column of this.table.columns) {
            if (columnName == column.name) return column;
         }
         return;
      }
      isViewable(columnName) {
         const column = this.findColumn(columnName);
         return column && column.displayed;
      }
      isDownloadable(columnName) {
         const column = this.findColumn(columnName);
         return column && column.downloadable;
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
         const rows = [this.h.tr({}, [
            this.h.th('Column'),
            this.h.th('View'),
            this.downloadable ? this.h.th('Download') : ''
         ])];
         const sortOptions = [ this.h.option({ value: '' }, '[ Default ]') ];
         for (const column of this.table.columns) {
            rows.push(this.h.tr({}, this.renderCells(column)));
            if (column.sortable) {
               const option = { value: column.name };
               if (column.name == this.table.resultset.state('sortColumn'))
                  option.selected = 'selected';
               sortOptions.push(this.h.option(option, column.label));
            }
         }
         const sizeOptions = [];
         for (const size of [10, 20, 50, 100]) {
            const option = { value: size };
            if (size == this.table.resultset.state('pageSize'))
               option.selected = 'selected';
            sizeOptions.push(this.h.option(option, size));
         }
         this.pageSize = this.h.select(
            { id: 'pageSize', name: 'pageSize' }, sizeOptions
         );
         this.sortBy = this.h.select(
            { id: 'sortBy', name: 'sortBy' }, sortOptions
         );
         this.sortDesc = this.h.input(
            { id: 'sortDesc', checked: this.table.resultset.state('sortDesc'),
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
               this.h.label({}, [this.sortDesc, 'Desc'])
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
               this.h.span({ className: 'dialog-close' }, 'X')
            ),
            this.renderForm()
         ]);
         this.table.topControl.append(this.dialog);
      }
   }
   Object.assign(Preference.prototype, HStateTable.Util.markup);
   class ConfigControl {
      constructor(table, methods) {
         const config = table.roles['configurable'];
         this.control;
         this.dialogState = false;
         this.label = config['label'];
         this.location = config['location'];
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
      }
      render(container) {
         const control = this.h.a(
            { className: 'preference-link', onclick: this.dialogHandler },
            [ this.h.span({ className: 'sprite sprite-preference' }),this.label]
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
      constructor() {
         this.textFile = null;
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
      async createLink(url, fDefault) {
         const { blob, filename } = await this.fetchBlob(url)
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
         table.resultset.parameterMap.nameMap('download', 'download');
         const config = table.roles['downloadable'];
         this.control;
         this.display = config['display'];
         this.downloader = new Downloader();
         this.filename = config['filename'];
         this.label = config['label'];
         this.location = config['location'];
         this.method = config['method'];
         this.table = table;
         this.downloadHandler = function(event) {
            event.preventDefault();
            table.resultset.state('download', this.method);
            const url = this.table.resultset.prepareURL();
            table.resultset.state('download', '');
            this.downloader.handler(url, this.filename);
         }.bind(this);
         const name = 'render' + this.location['control'] + 'Control';
         methods[name] = function(orig) {
            const container = orig();
            this.downloadControl.render(container);
            return container;
         };
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
// Package HStateTable.Role.Searchable
HStateTable.Role.Searchable = (function() {
   class SearchControl {
      constructor(table, methods) {
         const config = table.roles['searchable'];
         const paramMap = table.resultset.parameterMap;
         this.location = config['location'];
         this.messages;
         this.nameMap = paramMap.nameMap.bind(paramMap);
         this.searchControl;
         this.searchableColumns = [];
         this.state = table.resultset.state.bind(table.resultset);
         this.table = table;

         this.nameMap('searchColumn', 'search_column');
         this.nameMap('searchValue', 'search');

         for (const columnName of config['searchable_columns']) {
            for (const column of table.columns) {
               if (column.name == columnName) {
                  this.searchableColumns.push(column);
                  break;
               }
            }
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
            name: this.nameMap('searchValue'),
            placeholder: 'Search table...',
            type: 'text',
            value: this.state('searchValue') || null
         });
      }
      searchSelect(selectElements) {
         if (!this.searchableColumns.length) return;
         const options = [];
         const searchColumn = this.state('searchColumn') || null;
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
            className: 'search-select',
            name: this.nameMap('searchColumn')
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
            this.table.resultset.search({
               'searchColumn': select ? select.value : null,
               'searchValue': input.value
            });
            this.table.redraw();
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
         const messages = this.h.div();
         const column = this.state('searchColumn');
         const value = this.state('searchValue');
         if (column && value) {
            const handler = function(event) {
               event.preventDefault();
               this.table.resultset.search({
                  searchColumn: null, searchValue: null
               });
               this.table.redraw();
            }.bind(this);
            messages.className = 'status-messages';
            messages.append(this.h.span({ className: 'search-message' }, [
               'Searching for ',
               this.h.strong('"' + value + '"'),
               ' in ',
               this.h.strong('"' + column + '"'),
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
