({
	doInit : function(component, event, helper) {
		// var oppyName = helper.getParameterByName(component, 'oppyName') || 'opportunity name';
  //       component.set('v.oppyName', 'Copy of ' + oppyName);
	},
	showSpinner: function(component, event, helper) {
        component.set("v.showSpinner", true); 
   	},
    handleClone: function(component, event, helper){

        console.log('cloning now ....');
        helper.showLoadingImage(component, event, helper);
        helper.hideErrorMessageBox(component,event,helper);
        // var oppyId = helper.getParameterByName(component, 'oppyId');

        var action = component.get("c.clone");
        action.setParams({ 
          sourceOppyId: component.get("v.recordId"),
          cloneOppyName: component.get('v.oppyName')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            console.log('State: ' + state);
            
            if (state === "SUCCESS") {
                var resObj = JSON.parse(response.getReturnValue());
                console.log(resObj);
                // success
                if(resObj.code == 2000){
                    window.location = '/lightning/r/' + resObj.details + '/view';
                }else{
                    component.set('v.errorMessage', resObj.details);
                    helper.showErrorMessageBox(component,event,helper);
                    helper.hideLoadingImage(component,event,helper);
                }
        
            } else{
                component.set('v.errorMessage', 'System error. Please contact your system administrator.');
                helper.showErrorMessageBox(component,event,helper);
                helper.hideLoadingImage(component,event,helper);
            }
        });
        
        $A.enqueueAction(action);
    },
    hideErrorMessageBox: function(component,event,helper){
        helper.hideErrorMessageBox(component,event,helper);
    }
	
})