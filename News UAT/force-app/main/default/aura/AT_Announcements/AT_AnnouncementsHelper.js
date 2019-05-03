({
	displayAnnouncement: function(component, id) {
		var action = component.get('c.displayPopup');
        
        action.setParams({
            announcementID: id
        });
        
        action.setCallback(this, function(response) {
            // do nothing
        });
        
        $A.enqueueAction(action);
	},
    actionAnnouncement: function(component, id) {
		var action = component.get('c.actionPopup');
        
        action.setParams({
            announcementID: id
        });
        
        action.setCallback(this, function(response) {
            // do nothing
        });
        
        $A.enqueueAction(action);
	}
})