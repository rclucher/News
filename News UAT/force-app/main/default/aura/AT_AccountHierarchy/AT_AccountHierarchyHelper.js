({
	renameItemsToChildren: function(helper, data) {
        if (data && data.length > 0) {
            for (var i = 0; i < data.length; i++) {
                if (data[i].items && data[i].items.length) {
                    data[i]._children = data[i].items;
                    
                    helper.renameItemsToChildren(helper, data[i]._children);
                }
            }
        }
	}
})