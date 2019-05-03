({
	onInit: function(component, event, helper) {
        var mode = component.get('v.mode');
        var tableClasses = component.get('v.tableClasses');
        
        if (mode == 'embedded') component.set('v.tableClasses', tableClasses + ' embedded');
        
        helper.init(component, helper);
	},
    refresh: function(component, event, helper) {
        component.set('v.page', 1);
        
        helper.loadRecords(component, helper);
    },
    openFullView: function(component, event, helper) {
        var fullView = $A.get("e.force:navigateToComponent");
        fullView.setParams({
            componentDef : "c:AT_ListView",
            componentAttributes: {
                mode: 'full',
                title: component.get('v.title'),
                icon: component.get('v.icon'),
                config: component.get('v.config'),
                pageSize: 20,
                maxCount: 50000,
            }
        });
        fullView.fire();
    },
    newRecord: function(component, event, helper) {
        /*var createEvent = $A.get("e.force:createRecord");
        
        createEvent.setParams({"entityApiName": component.get('v.objectName')});
        
        createEvent.fire();*/
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          url: ("#/sObject/" + component.get('v.objectName') + "/new"),
          isredirect: true
        });
        urlEvent.fire();
    },
    handleAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {
            case 'edit':
    			var editRecordEvent = $A.get("e.force:editRecord");
    			editRecordEvent.setParams({
         			"recordId": row.Id.substring(1)
   				});
    			editRecordEvent.fire();
    
                break;
            case 'delete':
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                  url: ("#/sObject/" + row.Id.substring(1) + "/delete"),
                  isredirect: true
                });
                urlEvent.fire();
                
                break;
    	}
    },
    goBack: function(component, event, helper) {
        window.history.back();
    },
    goToPage: function(component, event, helper) {
        var page  = component.get('v.page');
        var pages = component.get('v.pages');
        
        helper.loadRecords(component, helper);
    },
    goToFirst: function(component, event, helper) {
        var page  = component.get('v.page');
        var pages = component.get('v.pages');
        
        component.set('v.page', 1);
        
        helper.loadRecords(component, helper);
    },
    goToLast: function(component, event, helper) {
        var page  = component.get('v.page');
        var pages = component.get('v.pages');
        
        component.set('v.page', pages);
        
        helper.loadRecords(component, helper);
    },
    goToPrevious: function(component, event, helper) {
        var page  = component.get('v.page');
        var pages = component.get('v.pages');
        
        if (page > 1) component.set('v.page', page - 1);
        
        helper.loadRecords(component, helper);
    },
    goToNext: function(component, event, helper) {
        //console.log('next');
        
        var page  = component.get('v.page');
        var pages = component.get('v.pages');
        
        if (page < pages) component.set('v.page', page + 1);
        
        helper.loadRecords(component, helper);
    }
})