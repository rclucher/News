/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This trigger is for Requirement: R-0798
 * Ability to allow users and managers to forecast their walk-ins into their pipeline.
 * This is batch to update stage and probablity for previous opportunities
 * History:
 * 13/09/2013  Bohao Chen  Created
 * 2016-01-15  Atul Gupta  Updated
 ---------------------------------------------------------*/
global class WalkinForecast_Batch implements Database.Batchable<sObject>
{
    global String query;
    global static final String opptyNamePart = 'Walk-in Forecast-Week-%';
    global static final Date todayDate = date.today();
    
    global WalkinForecast_Batch()
    {
        this.query = 'Select o.StageName, o.Probability ' 
                   + 'From Opportunity o '
                   + 'Where o.Name like: opptyNamePart '
                   + 'And o.CloseDate <=: todayDate '
                   + 'And o.StageName != \'Closed Lost\'';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Opportunity> oppties = (List<Opportunity>)scope;
        
        for(Opportunity oppty : oppties)
        {
            oppty.StageName = 'Closed Lost';
            oppty.Probability = 0;
        }
        
        // 2016-01-15 atul.gupta@bluewolfgroup.com - Exception Log framework method added to catch any exceptions on DML
        try{
            update oppties;
        } catch(Exception ex){
            ExLog.log(ex, 'config', oppties, 'Insert Opportunities in WalkinForecast_Batch Class');
        }
    }
    
    global void finish(Database.BatchableContext BC)
    {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
                        FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        
        //SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - Consolidate common function in Batch Utility class
        Batch_Utility.errorHandling(a, 'Walk-in Forecast Batch');
    }
}