/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This class contains unit tests for validating the behavior of TargetToQuota_Batch and helper class TargetToQuota_Helper
 * Company: Salesforce.com
 * Date: 8/10/2013
 * History:
 * 8/10/2013   Bohao Chen       Created
 * 2015-12-21  Atul Gupta  Updated
 // 2016-01-15 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - TargetToQuota_Batch   95%
	//  - TargetToQuota_Helper  98%
 ----------------------------------------------------------*/
@isTest
private class TargetToQuota_Batch_Test 
{

    static testMethod void insertRevenuseSchedules() 
    {
        // create users
        List<User> users = TestDataFactory.createUsers(4, 'System Administrator', null, null, true);
        insert users;
        
        // create products
        List<Product2> products = TestDataFactory.createProductsWithFamily(4);
        insert products;
        
        // create target revenue schedules
        Date testDate = date.newinstance(2013, 7, 1);
        
        List<Revenue_Schedule__c> revenueSchedules = TestDataFactory.createRevenueSchedules(products, 12, true, testDate, users);
        insert revenueSchedules;

        
        revenueSchedules = [Select Id, Rev_Date__c, Product_Family__c, OwnerId, Target__c 
                            From Revenue_Schedule__c r 
                            Where r.Reporting_Type_L1__c = 'Target'];

        system.debug(logginglevel.error, '@ insertRevenuseSchedules revenueSchedules:' + revenueSchedules);

        Test.startTest();
        
        String query ='Select Id, Rev_Date__c, Product_Family__c, OwnerId, Target__c '
	                 + 'From Revenue_Schedule__c r Where r.Reporting_Type_L1__c = \'Target\'';

        
        TargetToQuota_Batch targetToQuota = new TargetToQuota_Batch(query);
        ID batchProcessId = Database.executeBatch(targetToQuota);
        
        Test.stopTest();
        
        // verify the answers for revenue schedules insertion
        Set<String> periodIds = new Set<String>();
        
        Map<String, Map<String, Map<String, RevenueForecast>>> quotaByPeriodIdByProductFamilyByUserId = new Map<String, Map<String, Map<String, RevenueForecast>>>();
                
        for(RevenueForecast rf : [Select r.StartDate, r.Quota, r.PeriodId, r.OwnerId, r.Id, r.ProductFamily 
                                  From RevenueForecast r 
                                  Where r.OwnerId IN: users])
        {
            periodIds.add(rf.PeriodId);
            
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
                quotaByPeriodIdByProductFamilyByUserId.get(rf.OwnerId).get(rf.ProductFamily).put(rf.PeriodId, rf);
            }
        }
    
        Map<String, Period> periodById = new Map<String, Period>([Select p.Id, p.Type, p.StartDate, p.EndDate From Period p Where p.Id IN: periodIds order by p.StartDate ASC]);
        
        for(User u : users)
        {
            system.assert(quotaByPeriodIdByProductFamilyByUserId.containsKey(u.Id));

            Set<String> productFamilies = quotaByPeriodIdByProductFamilyByUserId.get(u.Id).keySet();
            
            // product families should either be digital, print, magzine
            system.assert(productFamilies.contains('Digital'));
            system.assert(productFamilies.contains('Print Metro'));
            system.assert(productFamilies.contains('Print Community'));
            system.assert(productFamilies.contains('Magazine'));
            
            Date tmpDate;
            
            system.debug(logginglevel.error, '@insertRevenuseSchedules quotaByPeriodIdByProductFamilyByUserId for user: ' + u.Id + ' : ' + quotaByPeriodIdByProductFamilyByUserId.get(u.Id));
            
            for(String periodId : periodById.keySet())
            {
                for(String productFamily : quotaByPeriodIdByProductFamilyByUserId.get(u.Id).keySet())
                {
                    if(periodById.get(periodId).StartDate == date.newInstance(2013, 7, 1))
                    {
                        //system.assertEquals(400, quotaByPeriodIdByProductFamilyByUserId.get(u.Id).get(productFamily).get(periodId).Quota);
                    }
                    else if(periodById.get(periodId).StartDate == date.newInstance(2013, 7, 29))
                    {
                        //system.assertEquals(500, quotaByPeriodIdByProductFamilyByUserId.get(u.Id).get(productFamily).get(periodId).Quota);
                    }
                    else if(periodById.get(periodId).StartDate == date.newInstance(2013, 9, 2))
                    {
                        //system.assertEquals(300, quotaByPeriodIdByProductFamilyByUserId.get(u.Id).get(productFamily).get(periodId).Quota);
                    }   
                    else
                    {
                        //system.assert(false);
                    }                 
                }
            }
        }
    }

    static testMethod void updateRevenuseSchedules() 
    {
        // create users
        List<User> users = TestDataFactory.createUsers(4, 'System Administrator', null, null, true);
        insert users;
        
        // create products
        List<Product2> products = TestDataFactory.createProductsWithFamily(4);
        insert products;
        
        // create target revenue schedules
        Date testDate = date.newinstance(2013, 7, 1);
        
        List<Revenue_Schedule__c> revenueSchedules = TestDataFactory.createRevenueSchedules(products, 12, true, testDate, users);
        insert revenueSchedules;

        revenueSchedules = [Select Id, Rev_Date__c, Product__c, Product_Family__c, OwnerId, Target__c, Rev_Amount__c, External_ID__c 
                                    From Revenue_Schedule__c r 
                                    Where id IN :revenueSchedules AND r.Reporting_Type_L1__c = 'Target'];

        system.debug(logginglevel.error, '@ updateRevenuseSchedules revenueSchedules:' + revenueSchedules);

        
        // this block is mimicing the way target to quota batch runs
        // the reason is that we can't have the same batch to run twice in one test method
        Map<Id, Period> periodsByIdForHelper = new Map<Id, Period>();  
        Map<Date, Map<Date, String>> periodIdByEndDateByStartDateForHelper = new Map<Date, Map<Date, String>>();
        Map<String, Map<String, Map<String, decimal>>> crsByPeriodIdByProductFamilyByUserIdForHelper = new Map<String, Map<String, Map<String, decimal>>>();
        Map<String, Map<String, Map<String, RevenueForecast>>> quotaByPeriodIdByProductFamilyByUserIdForHelper = new Map<String, Map<String, Map<String, RevenueForecast>>>();
        
        TargetToQuota_Helper.prepareTargetToQuota(periodsByIdForHelper, periodIdByEndDateByStartDateForHelper);
        
        TargetToQuota_Helper.processTargetToQuota(revenueSchedules, 
                                                  crsByPeriodIdByProductFamilyByUserIdForHelper, 
                                                  quotaByPeriodIdByProductFamilyByUserIdForHelper,
                                                  periodIdByEndDateByStartDateForHelper);
                                                  
        TargetToQuota_Helper.convertTargetToQuota(crsByPeriodIdByProductFamilyByUserIdForHelper, 
                                                  quotaByPeriodIdByProductFamilyByUserIdForHelper,
                                                  periodsByIdForHelper);
        
        for(Revenue_Schedule__c rs : revenueSchedules)
        {
            rs.Rev_Amount__c = 200;

            System.debug('@ updateRevenuseSchedules rs:' + rs);
        }
        
        upsert revenueSchedules;
        
        Test.startTest();
        
        String query ='Select Id, Rev_Date__c, Product_Family__c, OwnerId, Target__c, Rev_Amount__c, External_ID__c '
                     + 'From Revenue_Schedule__c r Where r.Reporting_Type_L1__c = \'Target\'';

        
        TargetToQuota_Batch targetToQuota = new TargetToQuota_Batch(query);
        ID batchProcessId = Database.executeBatch(targetToQuota);
        
        Test.stopTest();
        
        // verify the answers for revenue schedules insertion
        Set<String> periodIds = new Set<String>();
        
        Map<String, Map<String, Map<String, RevenueForecast>>> quotaByPeriodIdByProductFamilyByUserId = new Map<String, Map<String, Map<String, RevenueForecast>>>();
                
        for(RevenueForecast rf : [Select r.StartDate, r.Quota, r.PeriodId, r.OwnerId, r.Id, r.ProductFamily 
                                  From RevenueForecast r 
                                  Where r.OwnerId IN: users])
        {
            periodIds.add(rf.PeriodId);
            
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
                quotaByPeriodIdByProductFamilyByUserId.get(rf.OwnerId).get(rf.ProductFamily).put(rf.PeriodId, rf);
            }
        }
    
        Map<String, Period> periodById = new Map<String, Period>([Select p.Id, p.Type, p.StartDate, p.EndDate From Period p Where p.Id IN: periodIds order by p.StartDate ASC]);
        
        for(User u : users)
        {
            system.assert(quotaByPeriodIdByProductFamilyByUserId.containsKey(u.Id));
            
                    //  Map<String, Map<String, RevenueForecast>> quotaByPeriodIdByProductFamily = quotaByPeriodIdByProductFamilyByUserId.get(u.Id);
            
            Set<String> productFamilies = quotaByPeriodIdByProductFamilyByUserId.get(u.Id).keySet();
            
            // product families should either be digital, print, magzine
            system.assert(productFamilies.contains('Digital'));
            system.assert(productFamilies.contains('Print Metro'));
            system.assert(productFamilies.contains('Print Community'));
            system.assert(productFamilies.contains('Magazine'));
            
            Date tmpDate;
            
            system.debug(logginglevel.error, '@updateRevenuseSchedules quotaByPeriodIdByProductFamilyByUserId for user: ' + u.Id + ' : ' + quotaByPeriodIdByProductFamilyByUserId.get(u.Id));
            
            for(String periodId : periodById.keySet())
            {
                for(String productFamily : quotaByPeriodIdByProductFamilyByUserId.get(u.Id).keySet())
                {
                    if(periodById.get(periodId).StartDate == date.newInstance(2013, 7, 1))
                    {
                        //system.assertEquals(800, quotaByPeriodIdByProductFamilyByUserId.get(u.Id).get(productFamily).get(periodId).Quota);
                    }
                    else if(periodById.get(periodId).StartDate == date.newInstance(2013, 7, 29))
                    {
                        //system.assertEquals(1000, quotaByPeriodIdByProductFamilyByUserId.get(u.Id).get(productFamily).get(periodId).Quota);
                    }
                    else if(periodById.get(periodId).StartDate == date.newInstance(2013, 9, 2))
                    {
                        //system.assertEquals(600, quotaByPeriodIdByProductFamilyByUserId.get(u.Id).get(productFamily).get(periodId).Quota);
                    }   
                    else
                    {
                        //system.assert(false);
                    }                 
                }
            }
        }
    }
}