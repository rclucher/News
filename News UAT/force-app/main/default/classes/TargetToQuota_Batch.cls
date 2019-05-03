/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: Target to Quota batch
 * Company: Salesforce.com
 * Date: 08/10/2013
 * History:
 * 8/10/2013   Bohao Chen       Created
 * 2016-01-05  Atul Gupta       Updated
 ---------------------------------------------------------*/
global class TargetToQuota_Batch implements Database.Batchable<sObject>, Database.Stateful
{
    global String query;
    
    global Map<String, Map<String, Map<String, decimal>>> crsByPeriodIdByProductFamilyByUserId;
    global Map<String, Map<String, Map<String, RevenueForecast>>> quotaByPeriodIdByProductFamilyByUserId;
    global Map<Id, Period> periodsById;
    global Map<Date, Map<Date, String>> periodIdByEndDateByStartDate;
    
    
    global TargetToQuota_Batch(String q)
    {
        this.query = q;
        this.crsByPeriodIdByProductFamilyByUserId = new Map<String, Map<String, Map<String, decimal>>>();
        this.quotaByPeriodIdByProductFamilyByUserId = new Map<String, Map<String, Map<String, RevenueForecast>>>();
        this.periodsById = new Map<Id, Period>();        
        this.periodIdByEndDateByStartDate = new Map<Date, Map<Date, String>>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        TargetToQuota_Helper.prepareTargetToQuota(this.periodsById, this.periodIdByEndDateByStartDate);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Revenue_Schedule__c> revenueSchedules)
    { 
        TargetToQuota_Helper.processTargetToQuota(revenueSchedules, 
                                                  this.crsByPeriodIdByProductFamilyByUserId, 
                                                  this.quotaByPeriodIdByProductFamilyByUserId,
                                                  periodIdByEndDateByStartDate);
    }
    
    global void finish(Database.BatchableContext BC)
    { 
       // Get the ID of the AsyncApexJob representing this batch job
       // from Database.BatchableContext.
       // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
                        FROM AsyncApexJob WHERE Id = :BC.getJobId()];        
            
        //SFE-766 2016-01-05 atul.gupta@bluewolfgroup.com - Consolidate common function in Batch Utility class
        Boolean errorFlag = Batch_Utility.errorHandling(a, 'Target to Quota Batch');

        if(!errorFlag)
        {
            TargetToQuota_Helper.convertTargetToQuota(crsByPeriodIdByProductFamilyByUserId, 
                                                  quotaByPeriodIdByProductFamilyByUserId,
                                                  periodsById);
        }
    }
}