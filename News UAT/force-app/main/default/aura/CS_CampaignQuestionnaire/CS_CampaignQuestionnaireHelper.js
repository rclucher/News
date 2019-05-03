({
	 clearAll: function(component, event) {
        // this method set all tabs to hide and inactive
        var getAllLI = document.getElementsByClassName("customClassForTab");
        var getAllDiv = document.getElementsByClassName("customClassForTabData");
        for (var i = 0; i < getAllLI.length; i++) {
            getAllLI[i].className = "slds-tabs--scoped__item  customClassForTab " + getAllLI[i].title;
            getAllDiv[i].className = "slds-tabs--scoped__content slds-hide customClassForTabData " + getAllLI[i].title + "TabData";;
        }

    },
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
  	validateInputFields: function(component,event,helper){
      var sections = component.get('v.questions');
      var valMessages = [];

      for(var i = 0; i < sections.length; i++){
        var sec = sections[i];
        var secVal = {'SectionName': sec.SectionName, 'Questions':[]};
        for(var j = 0; j < sec.QuestionWrappers.length; j++){
          if(sec.QuestionWrappers[j].isMandatory){
            var q = sec.QuestionWrappers[j];
            if(!q.Answer.Answer_Text__c       && !q.Answer.Answer_Phone__c 
              && !q.Answer.Answer_Percent__c  && !q.Answer.Answer_Email__c 
              && !q.Answer.Answer_Date__c     && !q.Answer.Answer_Numeric__c
              && !q.Answer.Answer_Currency__c && !q.Answer.Answer_Url__c
              && !q.Answer.Answer_Long_Text__c && !q.LongTextAdditional){
                
                secVal.Questions.push(q.QuestionText);
            }
          }
        }
        if(secVal.Questions.length > 0){
          valMessages.push(secVal);
        }
      }

      component.set('v.validationMessages', valMessages);

      var result = valMessages.length>0 ? false : true;
      component.set("v.allRequiredFieldsCompleted", result);
  		return result;
  	},
    handleInit: function(component,event,helper){
      var getAllQuestionnairDataAction = component.get("c.getAllQuestionnairData");
        getAllQuestionnairDataAction.setParams({ recordId: component.get('v.recId')});
        getAllQuestionnairDataAction.setCallback(this, function(response) {
            var state = response.getState();
            
            console.log('State: ' + state);
            
            if (state === "SUCCESS") {
              var resObj = JSON.parse(response.getReturnValue());

              // success
              if(resObj.code == 2000){
                var data = JSON.parse(resObj.details);
                console.log(data);
                component.set('v.questions', data);
              }
              // business error
              else if(resObj.code == 2100){
                // do nothing for now as no business error is defined so far
              }
              // system error
              else{
                var valMessages = [];
                var message = resObj.message;
                valMessages.push(message);
                component.set('v.validationMessagesBE', valMessages);
                helper.showErrorMessageBox(component,event,helper);
                window.scrollTo(0, 0);
              }
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
              var valMessages = [];
              valMessages.push('The highlighted fields contain incorrect data.  Please correct and  try to save the form again.');
              component.set('v.validationMessagesBE', valMessages);
              helper.showErrorMessageBox(component,event,helper);
              window.scrollTo(0, 0);
            }
        });
        
        $A.enqueueAction(getAllQuestionnairDataAction);
    },
    handleSave: function(component,event,helper){
      component.set('v.validationMessagesBE', []);
      var questions = component.get('v.questions');
      var recordId = helper.getParameterByName(component, 'id') || component.get("v.recordId");

      var action = component.get("c.submitQuestionnaire");
        action.setParams({ 
          results: JSON.stringify(questions) , 
          recordId: recordId,
          isCompleted: component.get("v.allRequiredFieldsCompleted")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            console.log('State: ' + state);
            
            if (state === "SUCCESS") {
                var resObj = JSON.parse(response.getReturnValue());

                // success
                if(resObj.code == 2000){
                  helper.showSuccessMessageBox(component,event,helper);
                  window.scrollTo(0, 0);
                }
                // business error
                else if(resObj.code == 2100){
                  var valMessages = [];
                  if(resObj && resObj.details && JSON.parse(resObj.details).length>0 ){
                    valMessages = JSON.parse(resObj.details);
                  }else{
                    valMessages.push('The highlighted fields contain incorrect data.  Please correct and  try to save the form again.');
                  }
                  component.set('v.validationMessagesBE', valMessages);
                  helper.showErrorMessageBox(component,event,helper);
                  window.scrollTo(0, 0);
                }
                // system error
                else{
                  var valMessages = [];
                  valMessages.push('Some system errors prohibited the operation to be complete. Please contact your System Administrator.');
                  component.set('v.validationMessagesBE', valMessages);
                  helper.showErrorMessageBox(component,event,helper);
                  window.scrollTo(0, 0);
                }
        
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
              var valMessages = [];
              valMessages.push('The highlighted fields contain incorrect data.  Please correct and  try to save the form again.');
              component.set('v.validationMessagesBE', valMessages);
              helper.showErrorMessageBox(component,event,helper);
              window.scrollTo(0, 0);
            }
        });
        
        $A.enqueueAction(action);
    },
  	showSuccessMessageBox: function(component,event,helper){
    	component.set('v.showSuccessMessage', true);
    },
    hideSuccessMessageBox: function(component,event,helper){
    	component.set('v.showSuccessMessage', false);
    },
    showErrorMessageBox: function(component,event,helper){
    	component.set('v.showErrorMessage', true);
    },
    hideErrorMessageBox: function(component,event,helper){
    	component.set('v.showErrorMessage', false);
    },
    openValidationModal: function(component, event, helper) {
      component.set("v.isValidationModalOpen", true);
    },
    closeValidationModal: function(component,event,helper){
      component.set("v.isValidationModalOpen", false);
    },
    openCancelModal: function(component, event, helper) {
      component.set("v.isCancelModalOpen", true);
    },
    closeCancelModal: function(component, event, helper) {
      component.set("v.isCancelModalOpen", false);
    }

})