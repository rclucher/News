({
    doInit : function(component, event, helper) {
        var allPromises = [];
        allPromises.push(helper.getUserDetails(component));
        Promise.all(allPromises).then($A.getCallback(function(results){
			helper.populateAllAds(component,helper);
        }),$A.getCallback(function(ErrorMessage){
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Unable to get logged in user details!",
                "message": ErrorMessage
            });
        }));
	},
    refreshComp : function(component, event, helper) {
        helper.populateAllAds(component,helper);
        component.find('socialProofLoader').reloadRecord(true)
    },
    handleClodeModal : function(component, event, helper) {
        if(!$A.util.isUndefined(component.get('v.overlay')) && component.get('v.overlay') !== null){
			component.get('v.overlay').close();
        }
	},
    deleteAd : function(component, event, helper) {
		var index = event.currentTarget.dataset.adindex;
        var allAds = component.get('v.allAds');
        var modalBody;
        $A.createComponent("c:NXX2_DeleteProofAdConfirmation", {recordId : allAds[index].Id},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Delete Proof Ad",
                                       body: modalBody, 
                                       showCloseButton: true
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
	},
    editAd : function(component, event, helper) {
		var index = event.currentTarget.dataset.adindex;
        var allAds = component.get('v.allAds');
        var modalBody;
        $A.createComponent("c:NXX2_FacebookAdContainer", {adStatus : 'Edit',recordId : allAds[index].Id,campaignId : component.get('v.recordId')},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Edit Facebook Ad",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "custom-modal-for-social-ad"
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
	},
    createNewVersion : function(component, event, helper) {
		var index = event.currentTarget.dataset.adindex;
        var allAds = component.get('v.allAds');
        var modalBody;
        $A.createComponent("c:NXX2_FacebookAdContainer", {adStatus : 'CreateNewVersion',recordId : allAds[index].Id,campaignId : component.get('v.recordId')},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Create New Version Of Facebook Ad",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "custom-modal-for-social-ad"
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
	},
    showAllVersion : function(component, event, helper) {
		var parentId = event.currentTarget.dataset.parentid;
        var modalBody;
        $A.createComponent("c:NXX2_SocialAdVersionContainer", {parentSocialAdId : parentId},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Edit Facebook Ad",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "custom-modal-for-social-ad"
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
	},
    createAd : function(component, event, helper) {
        var modalBody;
        var proof  = component.get('v.proof');
        var proofDetails = {};
        if(proof !== null){
            proofDetails = {'Start_Date__c' : proof.Campaign_Start_Date__c,'End_Date__c' : proof.Campaign_End_Date__c};
        }
        $A.createComponent("c:NXX2_FacebookAdContainer", {adStatus : 'Create',campaignId : component.get('v.recordId'),proofDetails : proofDetails},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Create Facebook Ad",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "custom-modal-for-social-ad"
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
	},
    createForm : function(component, event, helper) {
        var index = event.target.dataset.adindex;
        var adType = event.target.dataset.adtype;
        var allAds = component.get('v.allAds');
        var modalBody;
        $A.createComponent("c:NXX2_SocialAdForm", {adType : adType,adStatus : 'Create',parentSocialAdId : allAds[index].Id,campaignId : allAds[index].Social_Campaign__c},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Create Facebook Ad Form",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "custom-modal-for-social-ad"
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
	},
    updateForm : function(component, event, helper) {
        var formId = event.target.dataset.formid;
        var index = event.target.dataset.adindex;
        var adType = event.target.dataset.adtype;
        var allAds = component.get('v.allAds');
        var modalBody;
        $A.createComponent("c:NXX2_SocialAdForm", {adType : adType,adStatus : 'Edit',recordId : formId,parentSocialAdId : allAds[index].Id,campaignId : allAds[index].Social_Campaign__c},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Update Facebook Ad Form",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "custom-modal-for-social-ad"
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
	}
})