/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This is helper class for TargetToQuota_Batch
 * Company: Salesforce.com
 * Date: 03/10/2013
 * History:
 * 03/10/2013   Bohao Chen       Created
 ---------------------------------------------------------*/
public with sharing class TargetToQuota_Helper
{
    public static final String targetToQuotaQuery = 'Select Id, Rev_Date__c, Product_Family__c, OwnerId, Target__c '
                                           + 'From Revenue_Schedule__c r Where r.Reporting_Type_L1__c = \'Target\'';
    
    public static void prepareTargetToQuota(Map<Id, Period> periodsById, Map<Date, Map<Date, String>> periodIdByEndDateByStartDate)
    {
        for(Period p : [Select p.StartDate, p.EndDate, p.PeriodLabel, p.Number, p.Id, p.FiscalYearSettingsId From Period p 
                        Where p.Type = 'Month' and p.IsForecastPeriod = true order by p.StartDate DESC])
        {
            periodsById.put(p.Id, p);
            Map<Date, String> periodIdByEndDate = new Map<Date, String>();
            periodIdByEndDate.put(p.EndDate, p.Id);
            periodIdByEndDateByStartDate.put(p.StartDate, periodIdByEndDate);
        }
    }
    
    public static void processTargetToQuota(List<Revenue_Schedule__c> revenueSchedules, 
                                            Map<String, Map<String, Map<String, decimal>>> crsByPeriodIdByProductFamilyByUserId,
                                            Map<String, Map<String, Map<String, RevenueForecast>>> quotaByPeriodIdByProductFamilyByUserId,
                                            Map<Date, Map<Date, String>> periodIdByEndDateByStartDate)
    {
        Set<String> userIdSet = new Set<String>();
        Set<String> productFamilySet = new Set<String>();

        for(Revenue_Schedule__c crs : revenueSchedules)
        {
            userIdSet.add(crs.OwnerId);
            productFamilySet.add(crs.Product_Family__c);
        
            if(!crsByPeriodIdByProductFamilyByUserId.containsKey(crs.OwnerId))
            {
                crsByPeriodIdByProductFamilyByUserId.put(crs.OwnerId, new Map<String, Map<String, decimal>>());
            }
            
            if(!crsByPeriodIdByProductFamilyByUserId.get(crs.OwnerId).containsKey(crs.Product_Family__c))
            {
                crsByPeriodIdByProductFamilyByUserId.get(crs.OwnerId).put(crs.Product_Family__c, new Map<String, decimal>());
            }
                
            // get period id based on start date and end date of crs
            String periodId;
            
            //system.debug('===periodIdByEndDateByStartDate=== ' + periodIdByEndDateByStartDate);
            
            for(Date startDate : periodIdByEndDateByStartDate.keySet())
            { 
                if(crs.Rev_Date__c >= startDate)
                {
                    for(Date endDate : periodIdByEndDateByStartDate.get(startDate).keySet())
                    {
                        if(crs.Rev_Date__c <= endDate)
                        {
                            periodId = periodIdByEndDateByStartDate.get(startDate).get(endDate);
                            break;
                        }
                    }
                }
            }
                
            if(!crsByPeriodIdByProductFamilyByUserId.get(crs.OwnerId).get(crs.Product_Family__c).containsKey(periodId))
            {
                // initialise target amount to 0
                crsByPeriodIdByProductFamilyByUserId.get(crs.OwnerId).get(crs.Product_Family__c).put(periodId, 0);
            }
            
            decimal amount = crsByPeriodIdByProductFamilyByUserId.get(crs.OwnerId).get(crs.Product_Family__c).get(periodId);

            crsByPeriodIdByProductFamilyByUserId.get(crs.OwnerId).get(crs.Product_Family__c).put(periodId, amount + crs.Target__c);
        }
            
        system.debug('===crsByPeriodIdByProductFamilyByUserId=== ' + crsByPeriodIdByProductFamilyByUserId);
        
        system.debug('===userIdSet=== ' + userIdSet);
        system.debug('===productFamilySet=== ' + productFamilySet);
        
        for(RevenueForecast rf : [Select r.StartDate, r.Quota, r.PeriodId, r.OwnerId, r.Id, r.ProductFamily 
                                  From RevenueForecast r 
                                  Where r.OwnerId IN: userIdSet 
                                  And r.ProductFamily IN: productFamilySet
                                 ])
        {
                
            if(!quotaByPeriodIdByProductFamilyByUserId.containsKey(rf.OwnerId))
            {
                quotaByPeriodIdByProductFamilyByUserId.put(rf.OwnerId, new Map<String, Map<String, RevenueForecast>>());
            }
            
            if(!quotaByPeriodIdByProductFamilyByUserId.get(rf.OwnerId).containsKey(rf.ProductFamily))
            {
                quotaByPeriodIdByProductFamilyByUserId.get(rf.OwnerId).put(rf.ProductFamily, new Map<String, RevenueForecast>());
            }
            
            if(!quotaByPeriodIdByProductFamilyByUserId.get(rf.OwnerId).get(rf.ProductFamily).containsKey(rf.PeriodId))
            {
                rf.Quota = 0; // initialise and pre-reset quota to 0 in order to recalculate quota
                quotaByPeriodIdByProductFamilyByUserId.get(rf.OwnerId).get(rf.ProductFamily).put(rf.PeriodId, rf);
            }
        }
        
        system.debug('===quotaByPeriodIdByProductFamilyByUserId 1=== ' + quotaByPeriodIdByProductFamilyByUserId);
    }
    
    public static void convertTargetToQuota(Map<String, Map<String, Map<String, decimal>>> crsByPeriodIdByProductFamilyByUserId,
                                            Map<String, Map<String, Map<String, RevenueForecast>>> quotaByPeriodIdByProductFamilyByUserId,
                                            Map<Id, Period> periodsById)
    {
        // update revenue forecast (quota) if quota exist based on period id, product family and user id
        // insert revenue forecast (quota) if quota don't exist based on period id, product family and user id
        List<RevenueForecast> quotas = new List<RevenueForecast>();
        
        for(String userId : crsByPeriodIdByProductFamilyByUserId.keySet())
        {
            if(!quotaByPeriodIdByProductFamilyByUserId.containsKey(userId))
            {
                quotaByPeriodIdByProductFamilyByUserId.put(userId, new Map<String, Map<String, RevenueForecast>>());
            }
            
            for(String productFamily : crsByPeriodIdByProductFamilyByUserId.get(userId).keySet())
            {
               if(!quotaByPeriodIdByProductFamilyByUserId.get(userId).containskey(productFamily))
               {
                   quotaByPeriodIdByProductFamilyByUserId.get(userId).put(productFamily, new Map<String, RevenueForecast>());
               }
               
               for(String periodId : crsByPeriodIdByProductFamilyByUserId.get(userId).get(productFamily).keySet())
               {
                   if(!quotaByPeriodIdByProductFamilyByUserId.get(userId).get(productFamily).containsKey(periodId))
                   {
                    
                        system.debug('===periodId=== ' + periodId);
                        // using period Id to get start date of the period
                        // since new revenue forecast needs start date rather than period id 
                        Date startDate = periodsById.get(periodId).StartDate;
                    
                        RevenueForecast rf = TargetToQuota_Helper.createQuota(userId, productFamily, startDate);
                        quotaByPeriodIdByProductFamilyByUserId.get(userId).get(productFamily).put(periodId, rf);
                   }
                   
                   RevenueForecast rf = quotaByPeriodIdByProductFamilyByUserId.get(userId).get(productFamily).get(periodId);
                   
                   system.debug('===RevenueForecast rf=== ' + rf);
                   
                   if(rf.Quota == null)
                   {
                        rf.Quota = 0;
                   }
                   rf.Quota += crsByPeriodIdByProductFamilyByUserId.get(userId).get(productFamily).get(periodId);
                   
               }
            }
        }
        
        system.debug('===quotaByPeriodIdByProductFamilyByUserId 2=== ' + quotaByPeriodIdByProductFamilyByUserId);
        
        
        for(String userId : quotaByPeriodIdByProductFamilyByUserId.keySet())
        {
            for(String ProductFamily : quotaByPeriodIdByProductFamilyByUserId.get(userId).keySet())
            {
                for(String periodId : quotaByPeriodIdByProductFamilyByUserId.get(userId).get(productFamily).keySet())
                {
                    RevenueForecast rf = quotaByPeriodIdByProductFamilyByUserId.get(userId).get(productFamily).get(periodId);
                    
                    // if rf doesn't have id, it means this is new quota.
                    // In order to insert new quota, product family, start date and owner id (user id) are required
                    // if rf has id, we need to update quota
                    // In order to update existing quota, quota id and quota are required
                    quotas.add(rf);
                }
            }
        }
        
        system.debug('===quotas=== ' + quotas);
        
        upsert quotas;
    }    
    
    private static RevenueForecast createQuota(String userId, String productFamily, Date startDate)
    {
        RevenueForecast newRf = new RevenueForecast();
        newRf.ProductFamily = productFamily;
        newRf.StartDate = startDate;
        newRf.OwnerId = userId;
        newRf.Quota = 0;
        return newRf;
    }
}