({
	fetchCustomersTask : function(component, event, helper) {
        component.set("v.Spinner",true);
        var action = component.get("c.fetchCustomerTask"); 
        action.setParams({
            parentRecordId : component.get("v.ParentObjectRecordId"),
            ParentObjectName : component.get("v.ParentObjectName"),
            isExternalUser : component.get("v.externalUser")
        });
        action.setCallback(this, function(a) {
            console.log(a.getReturnValue());
            component.set("v.customerTaskResponse",a.getReturnValue());
            component.set("v.customerTasksList", component.get("v.customerTaskResponse.customerTaskDTOList"));
            component.set("v.originalDataCustomerTasksList", component.get("v.customerTaskResponse.customerTaskDTOList"));
            component.set("v.isUserHasCreateAccessToTask", component.get("v.customerTaskResponse.isUserHasCreateAccessToTask"));
            
            console.log('customerTasksList' + component.get("v.customerTasksList"));
            component.set("v.Spinner",false);
            
        });
        $A.enqueueAction(action);  
    },
	getUserDetails : function(component) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.fetchLoggedInUsersDetails"); 
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state == 'SUCCESS') {
                    var userDetails = actionResult.getReturnValue();
                    component.set('v.externalUser', userDetails.UserType == 'Standard' ? false : true);
                    resolve.call(this, userDetails);
                }else{
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            component.set("v.message",errors[0].message);
                            reject.call(this, errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action); 
        });
	},
    getData : function(component) {
        var action = component.get("c.getCustomerActivities");
        action.setParams({
            "limits": component.get("v.initialRows"),
            "offsets": component.get("v.rowNumberOffset"),
            "parentRecordId" : component.get("v.ParentObjectRecordId"),
                "ParentObjectName" : component.get("v.ParentObjectName")
        });
        action.setCallback(this, function(a) {
            component.set("v.data", a.getReturnValue());
            component.set("v.currentCount", component.get("v.initialRows"));
        });
        $A.enqueueAction(action);
    },
    fetchData: function(component , rows){
        return new Promise($A.getCallback(function(resolve, reject) {
            var currentDatatemp = component.get('c.getCustomerActivities');
            var counts = component.get("v.currentCount");
            currentDatatemp.setParams({
                "limits": component.get("v.initialRows"),
                "offsets": counts,
                "parentRecordId" : component.get("v.ParentObjectRecordId"),
                "ParentObjectName" : component.get("v.ParentObjectName")
            });
            currentDatatemp.setCallback(this, function(a) {
                resolve(a.getReturnValue());
                var countstemps = component.get("v.currentCount");
                countstemps = countstemps+component.get("v.initialRows");
                component.set("v.currentCount",countstemps);
            });
            $A.enqueueAction(currentDatatemp);
        }));
    },
    loadCustomerActivityDetails : function(component,event,helper,row){
        //Call Event to inform main component to open file preview
        var handleCustomerActivitiesDetailView = component.getEvent("handleCustomerActivitiesDetailView");
         handleCustomerActivitiesDetailView.setParams({
            "customerTask" : row,
            "closeTaskViewer" : true
         });
		handleCustomerActivitiesDetailView.fire();
    },
    fetchCustomerActivityProofRecordType:function(component,event,helper){
        //getCustomerActivityRecordTypeForProof
        var action = component.get("c.getCustomerActivityRecordTypeForProof");
        
        action.setCallback(this, function(a) {
            component.set("v.recordType", a.getReturnValue());
        });
        $A.enqueueAction(action);
    }

    
})