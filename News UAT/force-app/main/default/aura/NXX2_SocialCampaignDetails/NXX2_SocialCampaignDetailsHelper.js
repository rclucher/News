({
	initialize : function(component) {
        component.set('v.displaySpinner',true);
        window.setTimeout(
            $A.getCallback(function() {
                component.set('v.displaySpinner',false);
            }), 2000
        );
	}
})