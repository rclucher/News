({
	showModal : function(component) {      
        var modal = component.find("exampleModal");
        $A.util.removeClass(modal, 'hideDiv');        
    },
    
    hideModal : function(component) {
        var modal = component.find("exampleModal");
        component.set("v.filePreview.downloadUrl", '');
        $A.util.addClass(modal, 'hideDiv');
    },
    hideProcessing : function(component) {
        var processingDiv = component.find("processingDiv");
        $A.util.addClass(processingDiv, 'hideDiv');
    },
    showProcessing : function(component) {
        var processingDiv = component.find("processingDiv");
        $A.util.removeClass(processingDiv, 'hideDiv');
    },
})