/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This is batch class for opportunity line item in order to create or update related custom revenue schedule records
 * Company: Salesforce.com
 * Date: 02/10/2013
 * History:
 * 02/10/2013   Bohao Chen       Created
 * 2016-01-05   Darshan Gosar    Updated
 ---------------------------------------------------------*/
global class Crs_OpportunityLineItem_Batch implements Database.Batchable<sObject>, Database.Stateful
{
    global String query;
    global Datetime crsOpptyLineItemLastRunSuccessDatetime = Batch_Run_Start_Datetime__c.getAll().get('CRS Opportunity Line Item Batch').Run_Start_Datetime__c;
    global Datetime batchRunStartDatetime;
    
    global Crs_OpportunityLineItem_Batch()
    {
        this.query = CustomRevenueSchedule_Helper.crsOpptyLineItemQuery;
        
        if(Test.isRunningTest())
        {
            this.query += ' limit 200';
        }
        
        system.debug('@this.query: ' + this.query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        this.batchRunStartDatetime = datetime.now();
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<OpportunityLineItem> scope)
    { 
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems(scope);
    }
    
    global void finish(Database.BatchableContext BC)
    {
       // Get the ID of the AsyncApexJob representing this batch job
       // from Database.BatchableContext.
       // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
                        FROM AsyncApexJob WHERE Id = :BC.getJobId()];
                        
        // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
            // Consolidate common function in Batch Utility class
        Boolean errorFlag;
        errorFlag = Batch_Utility.errorHandling(a, 'CRS Opportunity Line Item Batch');
        
        if(!errorFlag){        
            // timestamp success completed run datetime in custom setting for 'CRS Opportunity Line Item Batch'
            Batch_Run_Start_Datetime__c runDatetime = Batch_Run_Start_Datetime__c.getAll().get('CRS Opportunity Line Item Batch');
            runDatetime.Run_Start_Datetime__c = this.batchRunStartDatetime;
            update runDatetime;          
        }
    }
}