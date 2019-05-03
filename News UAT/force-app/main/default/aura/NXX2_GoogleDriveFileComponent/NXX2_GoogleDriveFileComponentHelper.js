({
    downloadFile : function(component) {
        // debugger;
        var downloadURL = component.get("v.files.downloadUrl");
        // var a = window.document.createElement('a');
        //downloadURL = downloadURL.replace("sfsites/c/", "");
        //var string = downloadURL.indexOf("/contenthub");
        //var response = str.substring(string,str.length);
        /* a.href = downloadURL;                    
		a.target="_blank"      
        // Append anchor to body.
        document.body.appendChild(a);
        a.click();
        
        // Remove anchor from body
        document.body.removeChild(a);
        */
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":  downloadURL
        });
        urlEvent.fire();
    },
    downloadVidio : function(component){
        var code = document.getElementById('code').textContent;
        var blob = new Blob([code], { type: 'application/javascript' });
        var url = URL.createObjectURL(blob);
        var worker = new Worker(url);
        URL.revokeObjectURL(url);
        //
         var action = component.get("c.downloadFile");
        var fileId = component.get("v.files.id");
        action.setParams({
            fileId: fileId,
        });
        action.setCallback(this, function(a) {
            console.log(a.getReturnValue());
            var fileContent = a.getReturnValue();
            var url  = window.URL.createObjectURL(new Blob([fileContent], {type: component.get("v.files.mimeType")}));                    
            
         });
        $A.enqueueAction(action);
    },
    downloadFile123 : function(component) {
        var action = component.get("c.downloadFile");
        var fileId = component.get("v.files.id");
        var downloadURL = component.get("v.files.downloadUrl");
        action.setParams({
            fileId: fileId,
            downloadURL : downloadURL
        });
        action.setCallback(this, function(a) {
            console.log(a.getReturnValue());
            var fileContent = a.getReturnValue();
            var a = window.document.createElement('a');
            a.href = window.URL.createObjectURL(new Blob([fileContent], {type: 'image/jpeg'}));                    
            
            var templateName = 'test';
            a.download = templateName+'.jpg';
            
            // Append anchor to body.
            document.body.appendChild(a);
            a.click();
            
            // Remove anchor from body
            document.body.removeChild(a); 
        });
        $A.enqueueAction(action); 
}
})