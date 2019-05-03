@isTest(SeeAllData = true) // Need SeeAllData to test anything related to RevenueForecast
public class AT_SalesPerformance_Test {
    static void init() {
        // Make sure the current user has forecasting enabled
        User currentUser = new User(Id = UserInfo.getUserId(), ForecastEnabled = true);
        
        update currentUser;
    }
    
    @isTest
    static void testActuals() {
        List<AT_SalesPerformance.MonthPeriod> periods = AT_SalesPerformance.getCurrentAndNextPeriods(2);
        
        List<Id> periodIDs = new List<Id>();
        
        for (AT_SalesPerformance.MonthPeriod mp: periods) periodIDs.add(mp.periodID);
        
        Map<Id, Integer> periodMonths = AT_SalesPerformance.getPeriodMonths(periodIDs);
        
        List<AT_SalesPerformance.MonthPeriod> qtrPeriods = AT_SalesPerformance.getFYQuarterPeriods();
        
        List<Sales_Actuals__c> actuals = new List<Sales_Actuals__c>{
            new Sales_Actuals__c(Product_Family__c = 'Print', Amount__c = 1000, PeriodId__c = periodIDs[0], Date__c = System.Today()),
                new Sales_Actuals__c(Product_Family__c = 'Digital', Amount__c = 1000, PeriodId__c = periodIDs[0], Date__c = System.Today())
                };
                    
                    insert actuals;
        
        List<AT_SalesPerformance.Sales> data = AT_SalesPerformance.getSalesActualsForPeriods(periodIDs);
    }
    
    @isTest
    static void testPipeline() {
        List<AT_SalesPerformance.MonthPeriod> periods = AT_SalesPerformance.getCurrentAndNextPeriods(2);
        
        List<Id> periodIDs = new List<Id>();
        
        for (AT_SalesPerformance.MonthPeriod mp: periods) periodIDs.add(mp.periodID);
        
        List<AT_SalesPerformance.Sales> data = AT_SalesPerformance.getPipelineForPeriods(periodIDs);
    }
    
    @isTest
    static void testTargets() {
        List<AT_SalesPerformance.MonthPeriod> periods = AT_SalesPerformance.getCurrentAndNextPeriods(2);
        
        List<Id> periodIDs = new List<Id>();
        
        for (AT_SalesPerformance.MonthPeriod mp: periods) periodIDs.add(mp.periodID);
        
        List<AT_SalesPerformance.Sales> data = AT_SalesPerformance.getTargetsForPeriods(periodIDs);
    }
    
    @isTest
    static void UnitTest01(){        
        Test.startTest();
        testActuals();
        testPipeline();
        testTargets();
        Test.stopTest();
    }
    
}