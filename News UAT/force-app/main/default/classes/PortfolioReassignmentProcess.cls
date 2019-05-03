/** 
 *
 * @author      Paul Kang, Bluewolf 
 * @description Update all Opened Opportunities Portfolio Codes with the updated code from the parent Account
 * @description Modified 2018-02-11 Paul Kang   
 **/

global class PortfolioReassignmentProcess implements Database.Batchable<sObject>, Database.Stateful {

    global Set<Id> OpportunityIds;
    
    //String query = 'SELECT Id, Portfolio_Code__c, Account.Id, OwnerId, Name FROM Opportunity WHERE Portfolio_Code__c != null and StageName != \'Closed Won\' and IsDeleted = false';

    global Map<Id, Opportunity> openedOpps {get; set;}

    private final String portfolioCodeReassignment = 'Need attention';


    private Date ignoreOpportunityCreatedBefore() {
        Date ignoreOpportunitiesBefore = [SELECT Ignore_Opportunities_before__c 
                                        FROM Portfolio_Process_Settings__mdt 
                                        where Label ='Default'].Ignore_Opportunities_before__c;
        System.debug('--ignoreOpportunitiesBefore' +ignoreOpportunitiesBefore);
        return ignoreOpportunitiesBefore;
    }
    
    global PortfolioReassignmentProcess() {
        
        OpportunityIds = new Set<Id>();
    }

    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date ignoreOpportunitiesBefore = ignoreOpportunityCreatedBefore();
        System.debug('--Database.getQueryLocator' + BC);
        return Database.getQueryLocator([SELECT Id, Portfolio_Code__c, Account.Id, OwnerId, Name 
                        FROM Opportunity 
                        WHERE Portfolio_Code__c != null and 
                        StageName NOT IN ('Closed Won','Closed Lost') and
                        IsDeleted = false AND CreatedDate >=:ignoreOpportunitiesBefore]);
    }


    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
    
        //try {
            // Load all the Get the AccountId of the Opportunities
            Map<Id,Opportunity> acctOppMap = new Map<Id, Opportunity>();
            
            for(Opportunity oppt: scope) {
                acctOppMap.put(oppt.AccountId, oppt);
            }

            // Load Account_Portfolio_Relationship__c records
            Map<Id, Set<String>> acctPortCodesMap = new Map<Id,Set<String>>();

            for(Account_Portfolio_Relationship__c acct: [Select Id, 
                                                                Account__c, 
                                                                Portfolio_Code__c 
                                                                FROM Account_Portfolio_Relationship__c 
                                                                WHERE Account__c IN:acctOppMap.keySet() ]) {
                System.debug('--acctOppMap' + acctOppMap);
                if (acctPortCodesMap.containsKey(acct.Account__c)) {

                    Set<String> portCodeSet = acctPortCodesMap.get(acct.Account__c);
                    // add portfolio code if it doesn't already exist
                    portCodeSet.add(acct.Portfolio_Code__c);
                    // add the Set to the map
                    acctPortCodesMap.put(acct.Account__c, portCodeSet);
                }
                else {
                    // add a new AccountId with Set of portfolio codes
                    Set<String> portCodes = new Set<String>();
                    portCodes.add(acct.Portfolio_Code__c);
                    acctPortCodesMap.put(acct.Account__c, portCodes);
                }
                
                 System.debug('--acctPortCodesMap' + acctPortCodesMap);
            }

            // Loop through all the Booking System Portfolio Junction
            for(Booking_System_Portfolio_Junction__c bsa: [Select   Booking_System_Account__r.Customer_Account__c,
                                                                    Portfolio_Code__c 
                                                                    FROM Booking_System_Portfolio_Junction__c 
                                                                    WHERE Booking_System_Account__r.Customer_Account__c IN:acctOppMap.keySet()]) {

                string acctid = bsa.Booking_System_Account__r.Customer_Account__c;
                if (acctPortCodesMap.containsKey(acctid)) {

                    Set<String> portCodeSet = acctPortCodesMap.get(acctid);
                    // add portfolio code if it doesn't already exist
                    portCodeSet.add(bsa.Portfolio_Code__c);
                    // add the Set to the map
                    acctPortCodesMap.put(acctid, portCodeSet);
                }
                else {
                    // add a new AccountId with Set of portfolio codes
                    Set<String> portCodes = new Set<String>();
                    portCodes.add(bsa.Portfolio_Code__c);
                    acctPortCodesMap.put(acctid, portCodes);
                }
            }
            System.debug('**acctPortCodesMap' + acctPortCodesMap);
            // Loop through the Opportunities to check the Portfolio Code is different
            // and replace if it's 1 to 1 mapping
            System.debug('--Scope Size' +scope.size());
            if (scope.size() > 0) {

                // Loop through Map of Opportunities and get the PortfolioCodes
                for(Opportunity opp : scope) {
                    Boolean isMatch = false;
                    

                    // Get the Set codes which are different
                    Set<String> codes = acctPortCodesMap.get(opp.AccountId);
                    System.debug('###Codes'+ codes);
                    if (codes != null) {
                        if(String.isBlank(opp.Portfolio_Code__c)) {
                                    isMatch = false;
                                    System.debug('%%String isBlank isMatch'+isMatch);
                         }

                        else if (codes.size() == 1) {
                            for(String code : codes) {
                                opp.Portfolio_Code__c = code;

                                System.debug('@opp.portfolio_code__c ' + code);
                            }
                        } 
                        else if (codes.size() > 1) {
                            
                            isMatch = false;
                            for(String oppCode : codes) {
                                System.debug('@oppCode is: ' + oppCode + ' opp.Portfolio_Code__c is: ' + opp.Portfolio_Code__c);

                                if(String.isNotBlank(opp.Portfolio_Code__c) && opp.Portfolio_Code__c.contains(oppCode)) {
                                    isMatch = true;
                                    break;
                                }
                            }
                            System.debug('&&&&isMatch' +isMatch);
                            if (isMatch == false) {
                                opp.Portfolio_Code__c = portfolioCodeReassignment;
                                OpportunityIds.add(opp.Id);
                                System.debug('@Opportunity needs attention: ' + opp.Id + ' since more than 1 portfolios exist');
                                System.debug('--portfolioCodeReassignment ' + portfolioCodeReassignment);
                            }
                        }
                    }
                }
                // update the opportunity
                // 
                Database.SaveResult[] srList = Database.update(scope, false);
                
                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('@Successfully update Opportunity. Opportunity ID: ' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('@The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('@Opportunity fields that affected this error: ' + err.getFields());
                        }
                    }
                }                
            }
       /*}
        catch(Exception ex) {
            ExLog.log(ex, 'config', (SObject)null, '');     
        }*/
    }


    
    global void finish(Database.BatchableContext BC) {

        List<Opportunity> opptsReassigned = [Select Id, OwnerId, Portfolio_Code__c, Name 
                                            from Opportunity where Portfolio_Code__c=:portfolioCodeReassignment and StageName NOT IN ('Closed Won','Closed Lost')];

        System.debug('@opptsReassigned: ' + opptsReassigned.size());
        System.debug('--Owner Id ' + opptsReassigned);

        if (opptsReassigned.size() > 0) {
            SendReminder(opptsReassigned);

        }

        // notify the executing user context the job is complete
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                                TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id =:BC.getJobId()];
       // Send an email to the Apex job's submitter notifying of job completion.
       String opportunities = '';
       if (OpportunityIds.size() > 0) {
            for(Id oppId : OpportunityIds) {
                opportunities += '\n OpportunityId: ' + oppId + ' needs action from Opportunity Owner';
            }
       }

        string subject = 'Portfolio reassignment ' + a.Status;
        string body = 'The batch Portfolio_Reassignment job processed ' + a.TotalJobItems +
       ' batches with '+ a.NumberOfErrors + ' failures.\n Total Number of Opportunity Codes Updated: ' + opportunities;
        String[] toAddresses = new String[] {a.CreatedBy.Email};

        Batch_Utility.sendEmail(toAddresses,subject,body);
    }

    
    @TestVisible
    private void SendReminder(List<Opportunity> opptsAttention) {
        System.debug('--INSIDE Send Reminder');

        EmailTemplate template = [select Id from EmailTemplate where developerName =: 'Portfolio_Reassignment'];

        List<Task> taskList = new List<Task>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Opportunity opp : opptsAttention) {

            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(template.Id, opp.OwnerId, opp.Id);
            if (email != null) {
                email.saveAsActivity = false;
                emails.add(email);
            }
        }


        Messaging.sendEmail(emails);

    }

    
}