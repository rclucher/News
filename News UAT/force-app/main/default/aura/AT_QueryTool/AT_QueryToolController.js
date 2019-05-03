({
	submit: function(component, event, helper) {
        var query = component.get('v.query');
        
		var action = component.get('c.query');
        
        console.log(`Query: ${query}`);
        
        action.setParams({soql: query});
        
        action.setCallback(this, function(response) {
        	var state = response.getState();
            
            if (state == 'SUCCESS') {
                var value = response.getReturnValue();
                
                console.log(value.columns);
                
                //console.log(value.data);
                
                var data = [];
                
                if (value.data && (value.data.length > 0)) {
                    value.data.forEach(d => {
                        var row = [];
                        
                        for (var key in d) {
                        	row.push({key: key, value: d[key]});
                    	}
                
                		data.push(row);
                    });
                }
                
                component.set('v.columns', value.columns);
                component.set('v.data', data);
            } else {
                console.log('ERROR');
            }
        });
        
        $A.enqueueAction(action);
	},
    select: function(component, event, helper) {
        var el = document.querySelector('#results'); //component.find('results').getElement();
        
        console.log(el);
        
        var body = document.body, range, sel;
        if (document.createRange && window.getSelection) {
            var selection = window.getSelection ();
            var rangeToSelect = document.createRange ();
            rangeToSelect.selectNodeContents (el);

            selection.removeAllRanges ();
            selection.addRange (rangeToSelect);

        }
        
        /*if (document.body.createTextRange) {
            const range = document.body.createTextRange();
            range.moveToElementText(node);
            range.select();
        } else if (window.getSelection) {
            const selection = window.getSelection();
            const range = document.createRange();
            range.selectNodeContents(node);
            selection.removeAllRanges();
            selection.addRange(range);
        } else {
            console.warn("Could not select text in node: Unsupported browser.");
        }*/
    }
})