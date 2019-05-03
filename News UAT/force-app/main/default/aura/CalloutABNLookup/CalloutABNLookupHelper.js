({
	 showToastDialog: function(title, type, message) {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
                        "title": title,
                        "type": type,
                        "message": message
        });

        resultsToast.fire();
    }
})