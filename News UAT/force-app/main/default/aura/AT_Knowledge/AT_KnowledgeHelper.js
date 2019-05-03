({
	loadKnowledge: function(component, helper) {
        var recordID = component.get('v.recordId');

        if (!recordID) {
            console.log('Knowledge: Home');
            
            var action = component.get('c.queryKnowledge');
            
            var filterField = component.get('v.filterField');
            var filterValue = component.get('v.filterValue');
            
            if (!filterValue) filterValue = '';
            
            console.log(filterField + ': ' + filterValue);
            
            action.setParams({
                pageName : 'Home',
                filterFieldName: filterField,
                filterValue: filterValue
            });
            
            console.log('knowledge: params:');
            console.log({
                pageName : 'Home',
                filterFieldName: filterField,
                filterValue: filterValue
            });
            
            console.log('knowledge: setting callback');
            
            action.setCallback(this, function(response) {
                helper.knowledgeLoaded(component, helper, response);
            });
            
            console.log('knowledge: enqueuing action');
            $A.enqueueAction(action);
        } else if (!recordID.startsWith('006')) {
            var action = component.get('c.queryKnowledge');
            
            var filterField = component.get('v.filterField');
            var filterValue = component.get('v.filterValue');
            
            var page = 'Home';
            
            if (recordID.startsWith('001')) page = 'Account';
            if (recordID.startsWith('00Q')) page = 'Lead';
            
            console.log('Knowledge: ' + page);
            
            action.setParams({
                pageName : page,
                filterFieldName: filterField,
                filterValue: filterValue
            });
            
            action.setCallback(this, function(response) {
                helper.knowledgeLoaded(component, helper, response);
            });
            
            $A.enqueueAction(action);
        } else {
            console.log('Knowledge: Opportunity');
            
            var action = component.get('c.queryKnowledge');
            
            action.setParams({
                pageName : 'Opportunity',
                filterFieldName: 'Opportunity_Stage__c',
                filterValue: recordID
            });
            
            action.setCallback(this, function(response) {
                helper.knowledgeLoaded(component, helper, response);
            });
            
            $A.enqueueAction(action);
        }
	},
    knowledgeLoaded: function(component, helper, response) {
        console.log('knowledge: callback running');
        console.log(response);
        
        if ((response != undefined) && (response != null)) {
            var state = response.getState();
            
            console.log('Knowledge state: ' + state);
            
            var pageSize = component.get('v.pageSize');
            
            component.set('v.currentPage', 1);
    
            if (state === "SUCCESS") {
                var all = response.getReturnValue().articles;
                
                var contentTypes = response.getReturnValue().contentTypes;
                
                var pages = Math.ceil(all.length / pageSize);
                
                component.set('v.contentTypes', contentTypes);
                
                component.set('v.multipleContentTypes', ((contentTypes != null) && (contentTypes.length > 1)));
                
                component.set('v.multiplePages', (pages > 1));
                
                component.set('v.pageCount', pages);
                
                component.set('v.knowledge', all);
                
                component.set('v.filtered', all);
                
                component.set('v.loaded', true);
                
                component.set('v.search', null);
                
                helper.paginate(component, helper);
                
                console.log('showSearch: ' + component.get('v.showSearch'));
                console.log('searching: ' + component.get('v.searching'));
                console.log('multiplePages: ' + component.get('v.multiplePages'));
                console.log('loaded: ' + component.get('v.loaded'));
                console.log('recordId: ' + component.get('v.recordId'));
                console.log('multipleContentTypes: ' + component.get('v.multipleContentTypes'));
            } else if (state === "INCOMPLETE") {
                console.log('incomplete');
                
                component.set('v.contentTypes', null);
                component.set('v.multipleContentTypes', false);
                component.set('v.knowledge', null);
                component.set('v.filtered', null);
                component.set('v.pageData', null);
                component.set('v.pageCount', 0);
                component.set('v.multiplePages', false);
                component.set('v.currentPage', 0);
                component.set('v.loaded', false);
                component.set('v.search', null);
            } else if (state === "ERROR") {
				var errors = response.getError();
                
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Knowledge Error: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                
                component.set('v.contentTypes', null);
                component.set('v.multipleContentTypes', false);
                component.set('v.knowledge', null);
                component.set('v.filtered', null);
                component.set('v.pageData', null);
                component.set('v.pageCount', 0);
                component.set('v.multiplePages', false);
                component.set('v.currentPage', 0);
                component.set('v.loaded', false);
                component.set('v.search', null);
            }
        }
    },
    handleSearch: function(component, helper) {
        var contentType = component.get('v.selectedContentType');
        
        var searchText = component.get('v.search');
        
        var all = component.get('v.knowledge');
        
        var pageSize = component.get('v.pageSize');
        
        if ((searchText == undefined) || (searchText == null) || (searchText == '')) {
            component.set('v.searching', false);
            
            var filtered = new Array();
            
            for (var i = 0; i < all.length; i++) {
                var value = Object.assign({}, all[i]);
                
                if ((contentType != undefined) && (contentType != null) && (contentType != '') && (contentType != '-')) {
                    if (value.contentType == contentType) {
                        filtered.push(value);
                    }
                } else {
            		filtered.push(value);
                }
            }
            
            var pages = Math.ceil(filtered.length / pageSize);
            
            component.set('v.multiplePages', (pages > 1));
            
            component.set('v.pageCount', pages);
            
            component.set('v.currentPage', 1);
            
            component.set('v.filtered', filtered);
            
            helper.paginate(component, helper);
        } else {
            component.set('v.searching', true);
            
            var filtered = new Array();
            
            var row = 0;
            
            for (var i = 0; i < all.length; i++) {
                var index = all[i].title.toLowerCase().indexOf(searchText.toLowerCase());
                
                if (index >= 0) {
                    var value = Object.assign({}, all[i]);
                    
                    value.order = index;
                    
                    value.title = helper.highlight(all[i].title, searchText);
                    
                    //value.rowClass = (i == (all.length - 1)) ? 'lastRow' : ''; //(row % 2 == 0) ? 'evenRow' : 'oddRow';
                    
                    if ((contentType != undefined) && (contentType != null) && (contentType != '') && (contentType != '-')) {
                    	if (value.contentType == contentType) {
                        	filtered.push(value);
                            
                            row++;
                        }
                    } else {
                        filtered.push(value);
                        
                        row++;
                    }
                    
                    //filtered.push(value);
                }
            }
            
            var sorted = filtered.sort(function (a,b) {
                if (a.order < b.order) {
                    return -1;
                } else if (a.order > b.order) {
                    return 1;
                } else {
                    return 0;
                }
            });
            
            if (sorted.length > 0) sorted[sorted.length - 1].rowClass = 'lastRow';
            
            component.set('v.filtered', sorted);
            
            var pages = Math.ceil(sorted.length / pageSize);
            
            component.set('v.multiplePages', (pages > 1));
            
            component.set('v.pageCount', pages);
            
            component.set('v.currentPage', 1);
            
            helper.paginate(component, helper);
        }
    },
    paginate: function(component, helper) {
        var pageCount = component.get('v.pageCount');
        
        var pageSize = component.get('v.pageSize');
        
        var currentPage = component.get('v.currentPage');
        
        var filtered = component.get('v.filtered');
        
        var pageData = new Array();
        
        var start = (currentPage - 1) * pageSize;
        
        for (var i = start; i < (start + pageSize); i++) {
            if (i >= filtered.length) break;
            
            var value = Object.assign({}, filtered[i]);
                
            pageData.push(value);
        }
        
        component.set('v.pageData', pageData);
        
        component.set('v.disablePrevious', (currentPage <= 1));
        component.set('v.disableNext', (currentPage >= pageCount));
    },
    highlight: function(text, searchText) {
      var escaped   = text; //.escapeHtml4();
      var lowerCase = escaped.toLowerCase();
      var search    = searchText.toLowerCase();
    
      var strings = new Array();
    
      var index = 0;
      var lastIndex = 0;
    
      while (index < lowerCase.length) {
        index = lowerCase.indexOf(search, lastIndex);
    
        if (index >= 0) {
          if (index > lastIndex) {
            strings.push(escaped.substring(lastIndex, index));
          }
    
          lastIndex = index + search.length;
    
          strings.push('<span class="highlight">' + escaped.substring(index, lastIndex) + '</span>');
        } else {
          strings.push(escaped.substring(lastIndex, lowerCase.length));
          break;
        }
      }
    
      return strings.join('');
    },
    openContent: function(component, helper, title, body) {
        component.set('v.contentTitle', title);
        component.set('v.contentURL', body);
        component.set('v.showContent', true);
    },
    closeContent: function(component, helper) {
        component.set('v.showContent', false);
    }
})