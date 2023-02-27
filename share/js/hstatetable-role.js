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
      async createLink(url, defaultFilename) {
         const { blob, filename } = await this.fetchBlob(url)
         if (this.textFile !== null) window.URL.revokeObjectURL(this.textFile);
         this.textFile = window.URL.createObjectURL(blob);
         const link = document.createElement('a');
         link.setAttribute('download', filename || defaultFilename);
         link.href = this.textFile;
         link.innerHTML = 'Downloading...';
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
      async clickHandler(url, filename) {
         this.clickLink(await this.createLink(url, filename));
      }
   }
   class DownloadControl {
      constructor(table, methods) {
         const config = table.roles['downloadable'];
         this.control;
         this.downloader = new Downloader();
         this.filename = config['filename'];
         this.label = config['label'];
         this.location = config['location'];
         this.method = config['method'];
         this.table = table;
         table.parameterMap.nameMap('download', 'download');
         const name = 'render' + this.location['download'] + 'Control';
         methods[name] = function(orig) {
            const container = orig();
            this.downloadControl.render(container);
            return container;
         };
      }
      render(container) {
         const control = document.createElement('a');
         control.className = 'download-link';
         const sprite = document.createElement('span');
         sprite.className = 'sprite sprite-download';
         control.append(sprite);
         control.append(document.createTextNode(this.label));
         control.addEventListener('click', function(event) {
            event.preventDefault();
            this.table.state('download', this.method);
            const url = this.table.resultset.prepareURL();
            this.table.state('download', '');
            this.downloader.clickHandler(url, this.filename);
         }.bind(this));
         if (this.control && container.contains(this.control)) {
            container.replaceChild(control, this.control);
         }
         else { container.append(control) }
         this.control = control;
      }
   }
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
         this.location = config['location'];
         this.messages;
         this.nameMap = table.parameterMap.nameMap.bind(table.parameterMap);
         this.searchControl;
         this.searchableColumns = [];
         this.state = table.state.bind(table);
         this.table = table;

         this.nameMap('searchColumn', 'search_column');
         this.nameMap('searchValue', 'search');

         for (const columnName of config['searchable_columns']) {
            for (const column of this.table.columns) {
               if (column.name == columnName) {
                  this.searchableColumns.push(column);
                  break;
               }
            }
         }

         const messages = 'render' + this.location['messages'] + 'Control';
         methods[messages] = function(orig) {
            const container = orig();
            this.searchControl.renderMessages(container);
            return container;
         };
         const search = 'render' + this.location['search'] + 'Control';
         methods[search] = function(orig) {
            const container = orig();
            this.searchControl.renderSearch(container);
            return container;
         };
      }
      searchAction(text) {
         const action = document.createElement('span');
         action.className = 'search-button';
         const button = document.createElement('button');
         button.type = 'submit';
         button.append(document.createTextNode(text));
         action.append(button);
         return action;
      }
      searchHidden(selectElements) {
         const hidden = document.createElement('span');
         hidden.className = 'search-hidden';
         for (const select of selectElements) { hidden.append(select) }
         return hidden;
      }
      searchInput() {
         const searchValue = this.state('searchValue') || null;
         const input = document.createElement('input');
         input.className = 'search-field';
         input.name = this.nameMap('searchValue');
         input.placeholder = 'Search table...';
         input.type = 'text';
         input.value = searchValue;
         return input;
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
            const option = document.createElement('option');
            option.className = 'search-select';
            option.value = column.name;
            if (selected) option.selected = 'selected';
            option.append(document.createTextNode(column.label));
            options.push(option);
         }
         const searchDisplay = document.createElement('span');
         searchDisplay.className = 'search-display';
//         searchDisplay.append(document.createTextNode(selectPrefix));
         selectElements.push(searchDisplay);
         const searchArrow = document.createElement('span');
         searchArrow.className = 'search-arrow';
         selectElements.push(searchArrow);
         const allOption = document.createElement('option');
         allOption.className = 'search-select';
         allOption.value = '';
         allOption.append(document.createTextNode('All'));
         const select = document.createElement('select');
         select.className = 'search-select';
         select.name = this.nameMap('searchColumn');
         select.append(allOption);
         for (const anOption of options) { select.append(anOption) }
         selectElements.push(select);
         return select;
      }
      renderSearch(container) {
         const selectElements = [];
         const select = this.searchSelect(selectElements);
         const wrapper = document.createElement('span');
         wrapper.className = 'search-wrapper';
         wrapper.append(this.searchHidden(selectElements));
         const input = this.searchInput();
         wrapper.append(input);
         wrapper.append(this.searchAction('Search'));
         const control = document.createElement('form');
         control.className = 'search-box';
         control.method = 'get';
         control.append(wrapper);
         control.addEventListener('submit', function(event) {
            event.preventDefault();
            this.table.resultset.search({
               'searchColumn': select ? select.value : null,
               'searchValue': input.value
            });
            this.table.redraw();
         }.bind(this));
         if (this.searchControl && container.contains(this.searchControl)) {
            container.replaceChild(control, this.searchControl);
         }
         else { container.append(control) }
         this.searchControl = control;
      }
      renderMessages(container) {
         const messages = document.createElement('div');
         const column = this.state('searchColumn');
         const value = this.state('searchValue');
         if (column && value) {
            messages.className = 'status-messages';
            const searchMessage = document.createElement('span');
            searchMessage.className = 'search-message';
            messages.append(searchMessage);
            searchMessage.append(document.createTextNode('Searching for '));
            const searchValue = document.createElement('strong');
            searchValue.append(document.createTextNode('"' + value + '"'));
            searchMessage.append(searchValue);
            searchMessage.append(document.createTextNode(' in '));
            const searchColumn = document.createElement('strong');
            searchColumn.append(document.createTextNode('"' + column + '"'));
            searchMessage.append(searchColumn);
            const showAll = document.createElement('a');
            showAll.append(document.createTextNode('Show all'));
            searchMessage.append(showAll);
            showAll.addEventListener('click', function(event) {
               event.preventDefault();
               this.table.resultset.search({
                  searchColumn: null, searchValue: null
               });
               this.table.redraw();
            }.bind(this));
         }
         if (this.messages && container.contains(this.messages)) {
            container.replaceChild(messages, this.messages);
         }
         else { container.append(messages) }
         this.messages = messages;
      }
   }
   const modifiedMethods = {};
   return {
      initialise: function() {
         this.searchControl = new SearchControl(this, modifiedMethods);
      },
      around: modifiedMethods
   };
})();
