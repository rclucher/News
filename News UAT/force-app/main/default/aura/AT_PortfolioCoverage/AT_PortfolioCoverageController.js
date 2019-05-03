({
	onInit: function(component, event, helper) {
        var action = component.get('c.getCoverage');
        
        var mode = component.get('v.mode');
        
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var coverage = response.getReturnValue();
                
                var clients = coverage.clients;
                var futureBookings = coverage.futureBookings;
                var portfolioAccounts = coverage.portfolioAccounts;
                var portfolioNames = coverage.portfolioNames;
                
                var portfolios = [];
                
                var today = new Date().getTime();
                
                for (var pa in portfolioAccounts) {
                    var portfolio = {Id: pa, Name: portfolioNames[pa]};
                    
                    //console.log('Portfolio: ' + portfolio.Name);
                    
                    var accountIDs = portfolioAccounts[pa];
                    
                    //console.log('Client Accounts: ' + accountIDs);
                    
                    portfolio.withActivity = {trading: 0, atRisk: 0, lapsed: 0, longLapsed: 0};
                    portfolio.withoutActivity = {trading: 0, atRisk: 0, lapsed: 0, longLapsed: 0};
                    
                    portfolio.accounts = [];
                    portfolio.clients = 0;
                    
                    if (accountIDs) {
                        var accounts = [];
                        
                        for (var i = 0; i < accountIDs.length; i++) {
                            var hasFuture = false;
                            
                            if (futureBookings[accountIDs[i]]) hasFuture = true;
                            
                            var account = clients[accountIDs[i]];
                            
                            if (account) {
                                portfolio.accounts.push(account);
                                
                                var adWeeks = 1000;
                                var activityWeeks = 1000;
                                
                                if (account.Last_Booking_Last_Expiry_Appearance__c) {
                                    var lastAd = Date.parse(account.Last_Booking_Last_Expiry_Appearance__c);
                                    
                                    adWeeks = helper.weeksBetween(lastAd, today);
                                }
                                
                                if (account.Last_Client_Engagement__c) {
                                    var lastActivity = Date.parse(account.Last_Client_Engagement__c);
                                    
                                    activityWeeks = helper.weeksBetween(lastActivity, today);
                                }
                                
                                //console.log('Portfolio: ' + portfolio.Name + ', Client: ' + account.Name + ' [Future: ' + hasFuture + ']' + ', adWeeks: ' + adWeeks + ' (' + account.Last_Booking_Last_Expiry_Appearance__c + '), activityWeeks: ' + activityWeeks + ' (' + account.Last_Client_Engagement__c + ')');
                                
                                if (mode == 'SME/RE') {
                                    var withActivity = (activityWeeks <= 8) ? 1 : 0;
                                    var withoutActivity = (activityWeeks > 8) ? 1 : 0;
                                    
                                    if ((adWeeks <= 4) || hasFuture) {
                                        portfolio.withActivity.trading += withActivity;
                                        portfolio.withoutActivity.trading += withoutActivity;
                                    } else if ((adWeeks > 4) && (adWeeks <= 6) && !hasFuture) {
                                        portfolio.withActivity.atRisk += withActivity;
                                        portfolio.withoutActivity.atRisk += withoutActivity;
                                    } else if ((adWeeks > 6) && (adWeeks <= 13) && !hasFuture) {
                                        portfolio.withActivity.lapsed += withActivity;
                                        portfolio.withoutActivity.lapsed += withoutActivity;
                                    } else if ((adWeeks > 13) && !hasFuture) {
                                        portfolio.withActivity.longLapsed += withActivity;
                                        portfolio.withoutActivity.longLapsed += withoutActivity;
                                    }
                                } else {
                                    if ((adWeeks <= 13) || hasFuture) {
                                        portfolio.withActivity.trading += (activityWeeks <= 13) ? 1 : 0;;
                                        portfolio.withoutActivity.trading += (activityWeeks > 13) ? 1 : 0;;
                                    } else if ((adWeeks > 13) && (adWeeks <= 26) && !hasFuture) {
                                        portfolio.withActivity.atRisk += (activityWeeks <= 13) ? 1 : 0;;
                                        portfolio.withoutActivity.atRisk += (activityWeeks > 13) ? 1 : 0;;
                                    } else if ((adWeeks > 26) && (adWeeks <= 52) && !hasFuture) {
                                        portfolio.withActivity.lapsed += (activityWeeks <= 26) ? 1 : 0;;
                                        portfolio.withoutActivity.lapsed += (activityWeeks > 26) ? 1 : 0;;
                                    } else if ((adWeeks > 52) && !hasFuture) {
                                        portfolio.withActivity.longLapsed += (activityWeeks <= 52) ? 1 : 0;;
                                        portfolio.withoutActivity.longLapsed += (activityWeeks > 52) ? 1 : 0;;
                                    }
                                }
                                    
                                portfolio.clients++;
                            }
                        }
                    }
                    
                    portfolios.push(portfolio);
                }
                
                component.set('v.portfolios', portfolios);
                
                console.log('Portfolios:');
                console.log(portfolios);
                
                component.set('v.loading', false);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
                
                component.set('v.loading', false);
            }
        }));
        $A.enqueueAction(action);
	}
})