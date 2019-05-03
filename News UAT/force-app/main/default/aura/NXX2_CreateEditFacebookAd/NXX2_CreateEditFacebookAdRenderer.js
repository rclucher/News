({
	rerender : function(component, helper){
        if(component.get('v.adStatus') != 'Create' && !$A.util.isUndefined(component.get('v.adDetails').Ad_Type__c) && !component.get('v.pageInitialized')){
        	helper.initializeDropdown(component);
            $A.util.addClass(component.find('containerDiv'), 'edit');
            component.set('v.pageInitialized',true);
        }
        var adDetails = component.get('v.adDetails');
        if(adDetails['Creative_Type__c'] == 'Carousel' || adDetails['Creative_Type__c'] == 'Slideshow'){
            var elements = document.getElementsByClassName("file-count");
            if(!$A.util.isUndefined(elements) && elements !== null && elements.length > 0){
        		$A.util.addClass(elements[component.get('v.currentFileIndex')], 'active');
            }
        }
    }
})