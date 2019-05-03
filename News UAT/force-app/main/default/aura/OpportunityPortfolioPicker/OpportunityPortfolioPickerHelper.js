({
    assignDefaultPortfolio: function(component, event, helper) {

        var recId = component.get("v.recordId");
        console.log('record id: ' + recId);

        if (recId) {
            var action = component.get("c.getDefaultPortfolio");

            action.setParams({
                "opportunityId": recId
            });

            action.setCallback(this, function(response) {
                if (response.getState() == 'SUCCESS') {

                    // Call for Default Portfolio
                    var portfolio = JSON.parse(response.getReturnValue());
                    var picklist = component.find('portfolioId');
                    var portfolioList = component.get('v.portfolios');


                    if (portfolio != null) {
                        console.log('portfolio owner:' + JSON.stringify(portfolio));

                        // if portfolio is null
                        if (portfolio.defaultPortfolio == null) {

                            // there is no default from server opportunity
                            // check from picklist values
                            if (portfolioList != null) {
                                console.log('picklist values' + JSON.stringify(portfolioList));

                                if (portfolioList.length === 1) {
                                    // use the default value from picklist 
                                    picklist.set('v.value',portfolioList[0].value);
                                }
                                else {
                                    picklist.set("v.value", 'unspecified');                                
                                }
                            }

                        } else {                           
                             
                            console.log('portfolio defaultPortfolio ' + portfolio.defaultPortfolio);
                            picklist.set("v.value", portfolio.defaultPortfolio);                        
                        }

                        helper.checkCurrentUserIsOwner(portfolio.opportunityOwner, picklist);

                    }


                    // should only disable if there is only 1 selected from 
                } else if (response.getState() === 'ERROR') {
                    console.log('error ' + response.getState());
                }
            })

            $A.enqueueAction(action);
        }
    },
    toggleDisable: function(portfolios, component) {
        if (portfolios != null) {
            if (portfolios.length == 1) {

                //component.set("v.disabled", true);
                var picklist = component.find('portfolioId');
                console.log('component ' + component);
                picklist.set("v.disabled", true);
            }
        }
    },
    checkCurrentUserIsOwner: function(opptyOwner, picklist) {
        // Get user 
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        console.log('userid: ' + userId);

        if (opptyOwner != null) {

            // parse from 18 to 15 characters
            opptyOwner = opptyOwner.substring(0, opptyOwner.length - 3);

            if (opptyOwner !== userId) {
                // Lock the picklist
                //picklist.set("v.disabled", true);
            }
        }
    },
    showToastDialog: function(title, type, message) {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": title,
            "type": type,
            "message": message
        });

        resultsToast.fire();
    }
})