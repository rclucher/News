({
	doInit : function(component, event, helper) {
		var recordId = helper.getParameterByName(component, 'id') || component.get("v.recordId");
		var obj = helper.getParameterByName(component, 'obj');
		if(obj){
			component.set('v.obj', obj);
		}
		console.log(recordId);

		component.set('v.recId', recordId);
		helper.handleInit(component, event, helper);
		
	},
	tabChange: function(component, event, helper) {
		// debugger;
		console.log('tab changed...');
		helper.clearAll(component, event);
		var className;
		if(event.target && event.target.title){
			className = event.target.title;
			
		}else{
			var questions = component.get('v.questions');
			if(questions.length > 0){
				className = questions[0].SectionId;
			}
		}
		var getAllLI = document.getElementsByClassName(className);
		var getAllDiv = document.getElementsByClassName(className + "TabData");
		for (var i = 0; i < getAllLI.length; i++) {
            getAllLI[i].className = "slds-tabs--scoped__item slds-active customClassForTab " + className;
            getAllDiv[i].className = "slds-tabs--scoped__content slds-show customClassForTabData " + className + "TabData";
        }

    },
    handleSaveWithValidation: function(component, event, helper){
    	console.log('submitting.....');

    	// close all modals
    	helper.hideSuccessMessageBox(component,event,helper);
    	helper.hideErrorMessageBox(component,event,helper);

    	if(!helper.validateInputFields(component, event, helper)){
    		component.set("v.isValidationModalOpen", true);
    		return;
    	}

    	// execute save
    	helper.handleSave(component,event,helper);
    },
    handleSaveWithoutValidation: function(component, event, helper){
    	console.log('submitting.....');

    	// close all modals
    	helper.hideSuccessMessageBox(component,event,helper);
    	helper.hideErrorMessageBox(component,event,helper);
    	helper.closeValidationModal(component,event,helper);

    	// execute save
    	helper.handleSave(component,event,helper);
    },
    handleDownload: function(component, event, helper){
        window.open('/apex/CS_AnswersDownload?id=' + component.get('v.recId'));
    },
    handleDownloadHistory: function(component, event, helper){
        window.open('/apex/CS_AnswerHistoryDownload?id=' + component.get('v.recId'));
    },
    handleDoneRendering: function(component, event, helper){
    	if(!component.get('v.domLoaded') && component.get('v.questions')){
    		console.log('handleDoneRendering......');
			var getAllLI = document.getElementsByClassName('customClassForTab');
			var getAllDiv = document.getElementsByClassName("customClassForTabData");
			if(getAllLI.length>0) {
			    getAllLI[0].className = getAllLI[0].className + " slds-active";
			    getAllDiv[0].className = getAllDiv[0].className.replace("slds-hide", "slds-show");;
			}
    		component.set("v.domLoaded",true);
    	}
    },
	handleCancel: function(component, event, helper) {
		window.location = '/lightning/r/' +component.get('v.recId') + '/view';
	},
	showSpinner: function(component, event, helper) {
        component.set("v.showSpinner", true); 
   	},
    hideSpinner : function(component,event,helper){  
       component.set("v.showSpinner", false);
    },
    showSuccessMessageBox: function(component,event,helper){
    	helper.showSuccessMessageBox(component,event,helper);
    },
    hideSuccessMessageBox: function(component,event,helper){
    	console.log('hideSuccessMessageBox...');
    	helper.hideSuccessMessageBox(component,event,helper);
    },
    showErrorMessageBox: function(component,event,helper){
    	helper.showErrorMessageBox(component,event,helper);
    },
    hideErrorMessageBox: function(component,event,helper){
    	helper.hideErrorMessageBox(component,event,helper);
    },
    openValidationModal: function(component, event, helper) {
	  	helper.openValidationModal(component, event, helper);
	},
    closeValidationModal: function(component,event,helper){
    	helper.closeValidationModal(component, event, helper);
    },
    openCancelModal: function(component, event, helper) {
	  	helper.openCancelModal(component, event, helper);
	},
	closeCancelModal: function(component, event, helper) {
	  	helper.closeCancelModal(component, event, helper);
	},
	showFieldHistory: function(component, event, helper){
		if(event.target && event.target.name){
			var qId = event.target.name;
			var getHistory = document.getElementsByClassName(qId + 'History');
			for (var i = 0; i < getHistory.length; i++) {
	            getHistory[i].className = qId + "History slds-show";
	        }

	        var getShowHistoryLink = document.getElementsByClassName(qId + 'ShowHistoryLink');
			for (var i = 0; i < getShowHistoryLink.length; i++) {
	            getShowHistoryLink[i].className = qId + "ShowHistoryLink slds-hide";
	        }
		}	
	},
	hideFieldHistory: function(component, event, helper){	
		if(event.target && event.target.name){
			var qId = event.target.name;
			var getHistory = document.getElementsByClassName(qId + 'History');
			for (var i = 0; i < getHistory.length; i++) {
	            getHistory[i].className = qId + "History slds-hide";
	        }

	        var getShowHistoryLink = document.getElementsByClassName(qId + 'ShowHistoryLink');
			for (var i = 0; i < getShowHistoryLink.length; i++) {
	            getShowHistoryLink[i].className = qId + "ShowHistoryLink slds-show";
	        }
		}
	}
})