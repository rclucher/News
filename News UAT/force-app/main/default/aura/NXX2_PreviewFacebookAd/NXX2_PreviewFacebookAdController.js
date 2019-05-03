({
	doInit : function(component, event, helper) {
        var adDetails = component.get('v.adDetails');
		if(!$A.util.isUndefined(adDetails.uploadedFiles)){
        	component.set('v.customCarouselWidth',adDetails.uploadedFiles.length * 250);
        }
	},
    openLink : function(component, event, helper) {
        window.open(event.getSource().get("v.value"));
	},
    updateAdDetails : function(component, event, helper) {
        var adDetails = event.getParam("arguments").adDetails;
        component.set('v.adDetails',adDetails);
        if(!$A.util.isUndefined(adDetails) && !$A.util.isUndefined(adDetails.uploadedFiles)){
        	component.set('v.customCarouselWidth',adDetails.uploadedFiles.length * 250);
        }
	},
    handleChangeInAdContent : function(component, event, helper) {
        var adDetails = component.get('v.adDetails');
        if(!$A.util.isUndefined(adDetails) && !$A.util.isUndefined(adDetails.uploadedFiles)){
        	component.set('v.customCarouselWidth',adDetails.uploadedFiles.length * 250);
        }
	}
})