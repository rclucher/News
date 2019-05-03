({
	handleShowNotice : function(component, variant, title, message) {
        component.find('notifLib').showNotice({
            "variant": variant,
            "header": title,
            "message": message,
            closeCallback: function() {
                //alert('You closed the alert!');
            }
        });
    }
})