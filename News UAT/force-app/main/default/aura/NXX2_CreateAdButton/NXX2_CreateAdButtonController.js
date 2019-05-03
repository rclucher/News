({
    doInit: function (component, event, helper) {
        /*var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:NXX2_FacebookAdContainer",
            componentAttributes: {
                adStatus : 'Create'
            }
        });
        evt.fire();*/
        var modalBody;
        $A.createComponent("c:NXX2_FacebookAdContainer", {adStatus : 'Create'},
           function(content, status) {
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLib').showCustomModal({
                       header: "Social Ad Editor",
                       body: modalBody, 
                       showCloseButton: true,
                       cssClass: "mymodal"
                   })
               }                               
           });
    }
})