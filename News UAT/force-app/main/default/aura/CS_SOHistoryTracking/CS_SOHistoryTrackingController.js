({
	doInit : function(component, event, helper) {
		var salesOrderId = helper.getParameterByName(component, 'soId');
		component.set('v.salesOrderId', salesOrderId);

		var sourceId = helper.getParameterByName(component, 'src');
		if(!sourceId) sourceId = salesOrderId;
		component.set('v.sourceId', sourceId);


		helper.getCampaignInfo(component, event, helper);
		helper.initSelectOptions(component, event, helper);
		helper.getAllHistory(component, event, helper);
	},
	onChangeSnapshot: function(component, event, helper){
		var sourceAuraId = event.getSource().getLocalId();
		var index = sourceAuraId.startsWith("column1") 
						? 1 
						: sourceAuraId.startsWith("column2") 
						? 2 
						: sourceAuraId.startsWith("column3") 
						? 3 
						: 0;
		if(!component.get('v.object' + index) && !component.get('v.snapshot' + index)){
            helper.resetAll(component, index);
        }
		if(!component.get('v.object' + index)  || !component.get('v.snapshot' + index)){
            return;
        }
		helper.loadSnapshot(component, index);
	},
	toggleColumn : function(component, event, helper) {
		var column1 = component.find('column1');
		$A.util.toggleClass(column1,'slds-medium-size_4-of-12 slds-large-size_4-of-12');
		$A.util.toggleClass(column1,'slds-medium-size_6-of-12 slds-large-size_6-of-12');

		var column2 = component.find('column2');
		$A.util.toggleClass(column2,'slds-medium-size_4-of-12 slds-large-size_4-of-12');
		$A.util.toggleClass(column2,'slds-medium-size_6-of-12 slds-large-size_6-of-12');

		var column3= component.find('column3');
		$A.util.toggleClass(column3,'slds-transition-show');

		helper.resetAll(component, 3);
	},
	expandPanel: function(component, event, helper){
		var testcmp = component.find('controlPanel');
        $A.util.toggleClass(testcmp,'controlPanelExpanded');
	},
	toggleTable : function(component, event, helper) {
		console.log(event.target.title);

		var els = document.getElementsByClassName(event.target.title);
        for (var i = 0; i < els.length; i++) {
        	if(els[i].className.indexOf('slds-hide') >= 0){
        		
        		els[i].className = els[i].className.replace('slds-hide', '');
        	}else{
        		els[i].className = els[i].className + ' slds-hide';
        	}
        }
    },
    downloadCsv : function(component,event,helper){
    	console.log('downloading...');
    	for(var i=1; i < 4; i++){
    		var object = 'object' + i;
    		var snatshop = 'snapshot' + i;
    		var csv;
    		if(component.get('v.history' + i)){
    			csv = helper.generateCsv(component, i);   
    			if(csv){
            		var recordNumber = i === 1  ? 'One' : i === 2 ? 'Two' : i === 3 ? 'Three' : '';
    				var hiddenElement = document.createElement('a');
					hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
					hiddenElement.target = '_blank'; // 
					hiddenElement.download = 'AuditTrackingRecord' + recordNumber + '.csv';  // CSV file Name* you can change it.[only name not .csv] 
					document.body.appendChild(hiddenElement); // Required for FireFox browser
					hiddenElement.click(); // using click() js function to download csv file
    			}
    		}

    	}
    },
    back : function(component,event,helper){
    	console.log('going back ...');
    	// window.location = '/' + component.get('sourceId');
    	//window.location = '/lightning/r/' + component.get('v.sourceId') + '/view';
    	window.history.back();
    },

    
})