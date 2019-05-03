({
	doInit : function(component, event, helper) {
        
		var totalCnt = component.get("c.getTotalCount");
		totalCnt.setParams({
			"searchKeyword": component.get("v.searchKeyword ")
        });
        totalCnt.setCallback(this, function(a) {
            component.set("v.totalNumberOfRows", a.getReturnValue());
            if(component.get("v.totalNumberOfRows") == 0){
                component.set('v.loadMoreStatus', 'No data for this search');
            }else{
                helper.getData(component);
            }
        });
		$A.enqueueAction(totalCnt);
		
        var actions = [
            { label: 'Show details', name: 'show_details' },
            { label: 'Delete', name: 'delete' }
        ];
        component.set('v.columns', [
			{label: 'View', type: 'button',  typeAttributes: { label: 'View Accounts', name: 'view_details', title: 'Click to View Details'}},
            {label: 'First Name', fieldName: 'FirstName', type: 'text',sortable:true},
            {label: 'Last Name', fieldName: 'LastName', type: 'text',sortable:true},
            {label: 'Phone', fieldName: 'Phone', type: 'text'},
            {label: 'Email', fieldName: 'Email', type: 'text'},
        ]);
        
       
	},
	
    loadMoreData: function (component, event, helper) {
        //Display a spinner to signal that data is being loaded
        event.getSource().set("v.isLoading", true);
        //Display "Loading" when more data is being loaded
        component.set('v.loadMoreStatus', 'Loading');
        helper.fetchContactData(component,component.get('v.rowsToLoad'),event);
    },
    // Client-side controller called by the onsort event handler
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    handleSelect: function (component, event, helper) {
        var arr = component.get('v.data');
        var obj =  component.get("v.selectedRowsList");
        console.log('obj '+JSON.stringify(obj) );
        var selectedButtonLabel = event.getSource().get("v.label");
        console.log('Button label: ' + selectedButtonLabel);
        var updateAction = component.get("c.setBookStatus");
        updateAction.setParams({ status : selectedButtonLabel , books: obj});
        updateAction.setCallback(this, function(a) {
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(updateAction);
    },
            closeMe :function(component, event, helper){
            //Call Event to inform main component to refresh the view
   				var refreshParentPage = component.getEvent("refreshParentPage");
				refreshParentPage.setParams({
                    "refreshParentView" : true,
                    "ParentRecordId" : '1213'
				});
                refreshParentPage.fire();
                component.find("overlayLib").notifyClose();

               

            },
    updateSelectedText : function(component, event, helper){
        var selectedRows = event.getParam('selectedRows');
         console.log('selectedRows'+selectedRows);
        component.set("v.selectedRowsCount" ,selectedRows.length );
        let obj =[] ; 
        for (var i = 0; i < selectedRows.length; i++){
            obj.push({Name:selectedRows[i].Name});
        }
        component.set("v.selectedRowsDetails" ,JSON.stringify(obj) );
        component.set("v.selectedRowsList" ,event.getParam('selectedRows') );
    },
    handleHeaderAction: function (cmp, event, helper) {
        // helper.getData(cmp);
        var actionName = event.getParam('action').name;
        var colDef = event.getParam('columnDefinition');
        var columns = cmp.get('v.columns');
        var activeFilter = cmp.get('v.activeFilter');
        console.log('activeFilter-->'+activeFilter);
        if (actionName !== activeFilter) {
            var idx = columns.indexOf(colDef);
            var actions = columns[idx].actions;
           // console.log('actions'+actions)
            actions.forEach(function (action) {
                action.checked = action.name === actionName;
            });
            cmp.set('v.activeFilter', actionName);
            helper.updateBooks(cmp);
            cmp.set('v.columns', columns);
        }
    },
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'view_details':
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": '/account/'+row.AccountId,
                    "isredirect" :false
                });
                urlEvent.fire();
        }
    },
    handleRecordUpdated : function(cmp, event, helper){
        
    },handleClose : function(component, event, helper) {
        //Closing the Modal Window
         component.find("overlayLib").notifyClose();
		
	},
})