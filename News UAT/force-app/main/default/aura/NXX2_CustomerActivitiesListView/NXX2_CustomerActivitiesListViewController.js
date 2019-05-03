({
	doInit : function(component, event, helper) {
        var action = component.get("c.getIconName");
        action.setParams({ "sObjectName" : component.get("v.sObjectName") });
        action.setCallback(this, function(response) {
           component.set("v.iconName", response.getReturnValue() );
        });
        $A.enqueueAction(action);  
        //debugger;
        var allPromises = [];
        allPromises.push(helper.getUserDetails(component));
        Promise.all(allPromises).then($A.getCallback(function(results){
            if(component.get("v.recordId")!=undefined){
                component.set("v.ParentObjectRecordId", component.get("v.recordId"));
                helper.fetchCustomersTask(component, event, helper);
            }else{
                helper.fetchCustomersTask(component, event, helper);
            }
        }),$A.getCallback(function(ErrorMessage){
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Unable to get logged in user details!",
                "message": ErrorMessage
            });
        }));

        helper.fetchCustomerActivityProofRecordType(component, event, helper);
    },
    filterCustomerActivity: function (component, event, helper) {
		
		var rows = component.get('v.originalDataCustomerTasksList');
		 // This will contain the string of the "value" attribute of the selected

        var activeFilter = event.getParam("value");
        console.log('activeFilter Helper'+activeFilter)
        var filteredRows = rows;
        if (activeFilter == 'All') {
			component.set('v.customerTasksList', rows);
            return  rows; 
        }
        if (activeFilter !== 'All') {
            filteredRows = rows.filter(function (row) {
                if(row.Customer_Task.Status__c == activeFilter){
                    return  row; 
                }
                // return (activeFilter === 'In_Completed') ||(activeFilter === 'Pre_Order');
            });
        }
        component.set('v.customerTasksList', filteredRows);
    },
    

    loadDetails : function(component,event,helper){
    	var selectedItem = event.currentTarget;
        var divId = selectedItem.dataset.record;      
        var cmpTarget = component.find(divId);
        $A.util.toggleClass(cmpTarget,'slds-is-open');
    },
    onCustomerActivityPreview : function(component,event,helper){
    	 var customerTask = event.getParam("customerTask");
         var closeTaskViewer = event.getParam("closeTaskViewer");
         var objectIcon = component.get("v.iconName")
         
         /*
          * Stop Propagating Event
          */
         event.stopPropagation();
    	/**
         * Calling Aura:Method mentioned in NXX2_GoogleDriveFileViewer Results Component
         */
         var customerActivityDetailEditViewComponent = component.find("customerActivityDetailEditView");
        console.log("customerTask Information" + customerTask);
        var auraMethodResult = customerActivityDetailEditViewComponent.openCustomerActivityDetailViewer(customerTask,objectIcon);
        console.log("auraMethodResult: " + auraMethodResult);
    },
    loadCustomerActivities : function(component,event,helper){
        
        var params = event.getParam('arguments');
        console.log("parentRecordId: " + params.parentRecordId);
       
        component.set("v.ParentObjectRecordId", params.parentRecordId);
        helper.fetchCustomersTask(component, event, helper);
    },
    refreshView : function(component, event, helper){
        /**
         * This if is for loading refreshing the view from Social Campaign detail page
         */
        if(component.get("v.recordId")!=undefined){
            component.set("v.ParentObjectRecordId", component.get("v.recordId"));
        }
        helper.fetchCustomersTask(component, event, helper);
        /*
          * Stop Propagating Event
          */
         event.stopPropagation();
         component.get('v.overlay').close();
    }, 
    openQuickCreateActivityView : function(component, event, helper){

        var modalBody;
        if(component.get("v.recordId")!=undefined){
            component.set("v.ParentObjectRecordId", component.get("v.recordId"));
        }
        $A.createComponent("c:NXX2_CustomerTaskDetailEditView", {iconName : component.get("v.iconName"),parentRecordId : component.get("v.ParentObjectRecordId"),recordType:component.get("v.recordType"),handleCustomerActivityRefreshListEvent: component.getReference("c.refreshView")},
           function(content, status) {
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLib').showCustomModal({
                       header: "Create Customer Activity",
                       body: modalBody, 
                       showCloseButton: true,
                       cssClass: "custom-modal-for-customerActivity",
                       closeCallback: function() {
                          // alert('You closed the alert!');
                       }
                   }).then(function (overlay) {
                    component.set('v.overlay',overlay);
                });
               }                               
           });
    }, 
    loadSObJectRelatedCustomerTask : function(component, event, helper){ 

        var contactRecordId = event.getParam("parentRecordId");
        component.set("v.customerTasksList", []);
        component.set("v.originalDataCustomerTasksList", []);

        component.set("v.Spinner",true);
        var customerActivityAction = component.get("c.getAllAccessibleAccountCustomerTask"); 
        customerActivityAction.setParams({
            "contactId" : contactRecordId
        });
        customerActivityAction.setCallback(this, function(customerActivityResult) {
            var state = customerActivityResult.getState();
            if(state == 'SUCCESS') {
                console.log(customerActivityResult.getReturnValue());
            component.set("v.customerTaskResponse",customerActivityResult.getReturnValue());
            component.set("v.customerTasksList", component.get("v.customerTaskResponse.customerTaskDTOList"));
            component.set("v.originalDataCustomerTasksList", component.get("v.customerTaskResponse.customerTaskDTOList"));
            component.set("v.isUserHasCreateAccessToTask", component.get("v.customerTaskResponse.isUserHasCreateAccessToTask"));
            console.log('customerTasksList' + component.get("v.customerTasksList"));
            component.set("v.Spinner",false);
            }else{
                component.set("v.Spinner",false);
                var errors = customerActivityResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                    }
                }
            }

            
        });
        $A.enqueueAction(customerActivityAction);  
        

    }
})