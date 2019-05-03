({
    doInit : function(component, event, helper) {
        var modalBody;
        $A.createComponent("c:NXX2_CreateNewProof", {displayInModal : true},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Create Proof",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       closeCallback: function() {
                                           helper.navigateBack(component);
                                       }
                                   });
                               }                               
                           });
    }
})