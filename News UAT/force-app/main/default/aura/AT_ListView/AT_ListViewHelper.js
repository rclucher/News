({
    init: function(component, helper) {
        component.set('v.canCreate', false);
        
        var config = component.get('v.config');
        
        if (config) {
            var action = component.get('c.getObjectInfo');
            
            action.setParams({
                configName: config
            });
            
            action.setCallback(this, function(response) {
                if ((response != undefined) && (response != null)) {
                    var state = response.getState();
                    
                    if (state === "SUCCESS") {
                        component.set('v.objectName', response.getReturnValue().name);
                        component.set('v.canCreate', response.getReturnValue().canCreate);
                        component.set('v.title', response.getReturnValue().title);
                        component.set('v.icon', response.getReturnValue().icon);
                    } else if (state === "ERROR") {
                        var errors = response.getError();
        
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " + errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                    }
                }
                
                helper.loadRecords(component, helper);
            });            
            
            $A.enqueueAction(action);
        }
    },
    loadRecords: function(component, helper) {
        component.set('v.loading', true);
        
        var config = component.get('v.config');
        
        if (config) {
            var action = component.get('c.getRecords');
            
            var mode     = component.get('v.mode');
            var page     = component.get('v.page');
            var pageSize = component.get('v.pageSize');
            var maxCount = component.get('v.maxCount');
            
            action.setParams({
                configName: config,
                viewMode: (mode == 'embedded' ? 'compact' : mode),
                maxCount: maxCount,
                pageSize: pageSize,
                pageNumber: page
            });
            
            action.setCallback(this, function(response) {
                helper.recordsLoaded(component, helper, response);
            });
            
            //console.log('Querying records');
            
            $A.enqueueAction(action);
        } else {
            console.log('no config defined');
        }
    },
	recordsLoaded: function(component, helper, response) {
        //console.log('Got response:');
        //console.log(response)
        //
        var config = component.get('v.config');
        
		if ((response != undefined) && (response != null)) {
            var state = response.getState();
            
            //console.log('Response state: ' + state);
            
            if (state === "SUCCESS") {
                var mode = component.get('v.mode');
                var page = component.get('v.page');
                
                //console.log('Mode: ' + mode);
                
                var data = response.getReturnValue();
                
                //console.log('Return values:');
                //console.log(data);
                
                //console.log('Columns:');
                //console.log(columns);
                
                var total = data.total;
                var columns = data.columns;
                var pages = data.pages;
                var records = helper.transformData(columns, data.records);
                
                var actions = [
           			{label: 'Edit', name: 'edit'},
            		{label: 'Delete', name: 'delete'}
        		];
        
                //columns.push({type: 'action', typeAttributes: {rowActions: actions}});
                
                var pageList = new Array();
                
                var multiPage = (mode == 'full') && (pages > 1);
                
                for (var p = 1; p <= pages; p++) pageList.push(p);
                
                component.set('v.columns', columns);
                component.set('v.records', records);
                
                component.set('v.multiPage', (pages > 1));
                component.set('v.pages', pages);
                component.set('v.pageList', pageList);
                
                component.set('v.hasFirst', multiPage && (page > 1));
                component.set('v.hasLast', multiPage && (page < pages));
                component.set('v.hasPrevious', multiPage && (page > 1));
                component.set('v.hasNext', multiPage && (page < pages));
            } else if (state === "ERROR") {
                var errors = response.getError();

                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        }
        
        component.set('v.loading', false);
	},
    transformData: function(columns, records, config) {
        var transformed = new Array();
        
        var urlFields = new Array();
        
        var remapped = records.slice(0);
        
        for (var c = 0; c < columns.length; c++) {
            if (columns[c].type == 'url') urlFields.push(columns[c].fieldName);
        }
        
        for (var r = 0; r < remapped.length; r++) {
            for (var c = 0; c < urlFields.length; c++) {
                if (remapped[r][urlFields[c]]) {
                    if (!remapped[r][urlFields[c]].startsWith('/')) {
                    	remapped[r][urlFields[c]] = ('/' + remapped[r][urlFields[c]]);
                    }
                }
            }
        }
        
        for (var r = 0; r < records.length; r++) {
            var record = records[r];
            
            for (var property in record) {
                if (record.hasOwnProperty(property)) {
                    if (record[property].Name != undefined) {
                        record[property + '.Name'] = record[property].Name;
                    }
                }
            }
        }
        
        for (var r = 0; r < records.length; r++) {
            var row = new Array();
            
            for (var c = 0; c < columns.length; c++) {
                var column = columns[c];
                var record = records[r];
                
                var data = null;
                var url = null;
                
                if (column.type == 'url') {
                    var fieldName = column.typeAttributes.label.fieldName;
                    
                    data = record[fieldName];
                    
                    url = record[column.fieldName];
                    
                    if (!url.startsWith('/')) url = '/' + url;
                } else {
                    data = record[column.fieldName];
                }
                
                row.push({label: column.label, type: column.type, data: data, url: url});
            }
            
            transformed.push(row);
        }
        
        //if (config == 'At_Risk_Clients') return remapped;
        
        return transformed;
    }
})