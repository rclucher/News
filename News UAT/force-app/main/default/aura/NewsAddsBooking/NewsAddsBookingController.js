({
    doInit: function (component, event, helper) {
        var recordId = component.get('v.recordId');
        if (recordId === "" || recordId == undefined) {
            helper.handleShowNotice(component,'error','Invalid record to proceed.');
        }else{
            var bookingAction = $A.get("e.force:navigateToURL");
            bookingAction.setParams({
                "url": '/apex/LeapfrogBooking?Id=' + recordId,
                "isredirect": "true"
            });
            bookingAction.fire();
            $A.get("e.force:closeQuickAction").fire();
        }
    }
})