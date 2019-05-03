({
    doInit: function(component, event, helper) {
        var recId = component.get("v.recordId");

        console.log('record id: ' + recId);

        var self = this;

        if (recId) {
            var action = component.get("c.getPortfolios");
            action.setParams({
                "opportunityId": recId
            });

            action.setCallback(this, function(response) {

                let state = response.getState();
                if (state === "SUCCESS") {
                    var portfolios = response.getReturnValue();

                    if (portfolios != null) {
                        console.log(JSON.stringify(portfolios));
                    }
                    
                    // populate the list of 
                    component.set("v.portfolios", portfolios);

                    helper.assignDefaultPortfolio(component, event, helper)

                } else if (state === "ERROR") {
                    // Process error returned by server

                } else {
                    // Handle other reponse states
                }
            });
            $A.enqueueAction(action);
        }

    },
    assignPortfolio: function(component, event, helper) {
		var recId = component.get("v.recordId");
        var portfolioCode = component.find("portfolioId").get("v.value");

		console.log(component.get("v.value"));
        console.log('record id: ' + recId);
        console.log('portfolioId code: ' + portfolioCode);
        
       

        if (recId) {

            var action = component.get("c.assignPortfolioToOppty");
			
            //component.set("v.spinner", true);
             console.log(portfolioCode);
            action.setParams({
                "opportunityId": recId,
                "portfolioCode": portfolioCode
            });
		console.log(portfolioCode);
            action.setCallback(this, function(response) {

                var state = response.getState();
                if (state === 'SUCCESS') {
                    helper.showToastDialog('Portfolio Code updated', 'success', 'Opportunity updated with Portfolio Code: ' + portfolioCode);
                }
            });
            $A.get('e.force:refreshView').fire();
            $A.enqueueAction(action);
        } 
            
            
        }
    }

})