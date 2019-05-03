({
	doInit: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        
        if (recordId && (recordId.indexOf("001") == 0)) {
            var action = component.get("c.getPortfolios");
            
            action.setParams({
                recordId: recordId
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                 
                if (state == "SUCCESS"){
                    var result = response.getReturnValue();
                    console.log(response.getReturnValue());
                    var accountPortfolios = result.accPortfolios;
                    //console.log('--' + accountPortfolios);
                    var bsPortfolios = result.bookingSystemPortfolios;
                    //console.log('++' + bsPortfolios);
                    var portfolios = result.portfolioList;
                    console.log(portfolios);
                    
                    
                    
                   for(var p=0;  p < portfolios.length; p++){
                        var port = portfolios[p];
                       
                       console.log('Portfolio name: ' + port.Name);
                        var relatedAccounts = [];
                        var adpointIds = [];
                    	var accountNos = [];
                        
                       adpointIds = accountPortfolios[port.Id];
                       accountNos = bsPortfolios[port.Id];
                   
                        console.log(accountNos);
                        console.log(adpointIds);
                       
                        if(adpointIds && adpointIds.length > 0){
                            relatedAccounts = relatedAccounts.concat(adpointIds);
                            console.log('Ad Point IDs ' + relatedAccounts);
                        }
                        
						if(accountNos && accountNos.length > 0){
                            relatedAccounts = relatedAccounts.concat(accountNos);
                            console.log('Account Nos ' + relatedAccounts);
                        } 	
                       
                       port['relatedAccounts'] = relatedAccounts; 
                        console.log('3' + relatedAccounts);
                        
                    }
                    component.set("v.portfolios", portfolios);
                    component.set("v.portfolioCount", (portfolios ? portfolios.length : 0));
                    component.set("v.hasPortfolios", (portfolios ? true : false));
                    
                    console.log('Portfolios: ');
                    console.log(portfolios);
               } else if (state == "ERROR"){
                    var errors = response.getError();
                    
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            
                            component.set("v.errorMessage", errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                        
                        component.set("v.errorMessage", "Unknown error");
                    }
                }
            });
            
            $A.enqueueAction(action);
        } else {
            component.set("v.errorMessage", "This component is only valid for use on an Account record page");
        }
	}
})