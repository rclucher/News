({
    init : function(cmp, event, helper) {
        var targetColumns = [
            {label: "Month", fieldName: "Month", type: "string", actions: {}, sortable: false},
            {label: "Print", fieldName: "Print", type: "currency", actions: {}, sortable: false},
            {label: "Digital", fieldName: "Digital", type: "currency", actions: {}, sortable: false},
            {label: "Combined", fieldName: "Combined", type: "currency", actions: {}, sortable: false}
        ];
        
        cmp.set("v.targetColumns", targetColumns);
        
		helper.getData(cmp); 
    }
})