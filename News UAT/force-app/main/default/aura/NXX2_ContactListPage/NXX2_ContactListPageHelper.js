({
	getData : function(component) {
        var action = component.get("c.getContacts");
        action.setParams({
            "limits": component.get("v.initialRows"),
			"offsets": component.get("v.rowNumberOffset"),
			"searchKeyword": component.get("v.searchKeyword")
        });
        action.setCallback(this, function(a) {
            component.set("v.data", a.getReturnValue());
            component.set("v.originalData", a.getReturnValue());
            component.set("v.currentCount", component.get("v.initialRows"));
        });
        $A.enqueueAction(action);
    },
    fetchContactData : function(component , rows,event){
        var currentDatatemp = component.get('c.getContacts');
            var counts = component.get("v.currentCount");
            currentDatatemp.setParams({
                "limits": component.get("v.initialRows"),
				"offsets": counts ,
				"searchKeyword": component.get("v.searchKeyword")
            });
            currentDatatemp.setCallback(this, function(a) {
                //resolve(a.getReturnValue());
                var countstemps = component.get("v.currentCount");
                countstemps = countstemps+component.get("v.initialRows");
                component.set("v.currentCount",countstemps);
                 if (component.get('v.data').length >= component.get('v.totalNumberOfRows')) {
                component.set('v.enableInfiniteLoading', false);
                component.set('v.loadMoreStatus', 'No more data to load');
            	} else {
                var currentData = component.get('v.data');
                //Appends new data to the end of the table
                var newData = currentData.concat(a.getReturnValue());
                component.set('v.data', newData);
                component.set('v.loadMoreStatus', 'Please wait ');
            }
            event.getSource().set("v.isLoading", false);
                
            });
            $A.enqueueAction(currentDatatemp);
    },
    fetchData: function(component , rows){
        return new Promise($A.getCallback(function(resolve, reject) {
            var currentDatatemp = component.get('c.getContacts');
            var counts = component.get("v.currentCount");
            currentDatatemp.setParams({
                "limits": component.get("v.initialRows"),
				"offsets": counts ,
				"searchKeyword ": component.get("v.searchKeyword ")
            });
            currentDatatemp.setCallback(this, function(a) {
                resolve(a.getReturnValue());
                var countstemps = component.get("v.currentCount");
                countstemps = countstemps+component.get("v.initialRows");
                component.set("v.currentCount",countstemps);
            });
            $A.enqueueAction(currentDatatemp);
        }));
    },
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.data", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
})