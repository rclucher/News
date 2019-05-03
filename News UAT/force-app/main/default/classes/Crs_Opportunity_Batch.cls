/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This is batch class for opportunity in order to create or update related custom revenue schedule records
 * Company: Salesforce.com
 * Date: 02/10/2013
 * History:
 * 25/09/2013   Bohao Chen       Created
 * 2016-01-05   Darshan Gosar    Updated
 ---------------------------------------------------------*/
global class Crs_Opportunity_Batch implements Database.Batchable<sObject>, Database.Stateful
{
    global String query;
    global Datetime crsOpptyLastRunSuccessDatetime = Batch_Run_Start_Datetime__c.getAll().get('CRS Opportunity Batch').Run_Start_Datetime__c;
    global Datetime batchRunStartDatetime;
    
    global Crs_Opportunity_Batch()
    {
        this.query = CustomRevenueSchedule_Helper.crsOpptyQuery;
        
        if(Test.isRunningTest())
        {
            this.query += ' and Is_Test__c = true limit 200';
        }
        
        system.debug('@query: ' + this.query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        this.batchRunStartDatetime = datetime.now();
        return Database.getQueryLocator(this.query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope)
    {
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities(scope);
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
        errorFlag = Batch_Utility.errorHandling(a, 'Account Update TCS TAS Batch');
        
        if(!errorFlag){
            // timestamp success completed run datetime in custom setting for 'CRS Opportunity Line Item Batch'
            Batch_Run_Start_Datetime__c runDatetime = Batch_Run_Start_Datetime__c.getAll().get('CRS Opportunity Batch');
            runDatetime.Run_Start_Datetime__c = this.batchRunStartDatetime;
            update runDatetime;    
            
            try 
            {
                // run Crs_OpportunityLineItem_Batch
                Crs_OpportunityLineItem_Batch crsOpptyLiBatch = new Crs_OpportunityLineItem_Batch();
                Database.executeBatch(crsOpptyLiBatch);   
            }
            catch(Exception e) 
            {
                system.debug(logginglevel.error, '===Crs_OpportunityLineItem_Batch batch error: ' + e.getMessage());
            }
        }
    }
    
        
    webService static void executeBatches()
    {
        Crs_Opportunity_Batch crsOpptyBatch = new Crs_Opportunity_Batch();
        Database.executeBatch(crsOpptyBatch);
    }
}