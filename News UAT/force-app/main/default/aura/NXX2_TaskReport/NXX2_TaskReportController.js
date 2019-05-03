({
    doInit : function(component, event, helper) {
        helper.populateColumnLables(component);
        helper.fetchTaskFromServer(component,1);
    },
    goToDetailedView : function(component, event, helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.target.getAttribute("data-sObjectId")
        });
        navEvt.fire();
    },
    prevPage: function(component, event, helper) {
        component.set("v.currentPageNumber", component.get("v.currentPageNumber")-1);
    },
    nextPage: function(component, event, helper) {
        component.set("v.currentPageNumber", component.get("v.currentPageNumber")+1);
    },
    renderPage: function(component, event, helper) {
        helper.renderPage(component);
    }
})