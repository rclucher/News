({
	doInit: function(component, event, helper) {        
        var popup = component.get('c.getPopups');
        
        popup.setCallback(this, function(response) {
            console.log('Popups');
            console.log(response.getReturnValue());
            
            var announcements = response.getReturnValue();
            
            if (announcements && announcements.length > 0) {
                helper.displayAnnouncement(component, announcements[0].id);
                
                component.find('notifLib').showNotice({
                    "variant": "warning",
                    "header": announcements[0].title,
                    "message": announcements[0].text,
                    "mode": "pester",
                    closeCallback: function() {
                        helper.actionAnnouncement(component, announcements[0].id);
                    }
                });
            }
        });
        
        $A.enqueueAction(popup);
        
		var action = component.get('c.getAnnouncements');
        
        action.setCallback(this, function(response) {
            var announcements = response.getReturnValue();
            
            if (announcements) {
                for (var i = 0; i < announcements.length; i++) {
                    if (announcements[i].text) {
                        announcements[i].text = announcements[i].text.replace(new RegExp('\\n', 'g'), '').
                        											  replace(new RegExp('<br/>', 'g'), '').
                                                                      replace(new RegExp('<br />', 'g'), '').
                        											  replace(new RegExp('<p[^/>]*>', 'g'), '').
                        											  replace(new RegExp('</p>', 'g'), '');
                    }
                }
            }
            
            component.set('v.announcements', announcements);
        });
        
        $A.enqueueAction(action);
	}
})