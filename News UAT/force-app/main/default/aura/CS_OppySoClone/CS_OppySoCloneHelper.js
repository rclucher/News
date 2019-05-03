({
	getParameterByName: function(component, name, url) {
	    if (!url) {
	        url = window.location.href;
	    }

	    name = name.replace(/[\[\]]/g, "\\$&");
	    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
	    var results = regex.exec(url);
	    if (!results) {
	      return null;
	    }
	    if (!results[2]) {
	      return '';
	    }

	    return decodeURIComponent(results[2].replace(/\+/g, " "));
  	},
  	showErrorMessageBox: function(component,event,helper){
    	component.set('v.showErrorMessage', true);
    },
    hideErrorMessageBox: function(component,event,helper){
    	component.set('v.showErrorMessage', false);
    },
    showLoadingImage: function(component,event,helper){
    	component.set('v.showSpinner', true);
    },
    hideLoadingImage: function(component,event,helper){
    	component.set('v.showSpinner', false);
    },
})