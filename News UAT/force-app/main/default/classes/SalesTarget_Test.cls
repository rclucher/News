@isTest(SeeAllData=true)
public class SalesTarget_Test {
	/*@testSetup
    static void init() {
        // Make sure the current user has forecasting enabled
        User currentUser = new User(Id = UserInfo.getUserId(), ForecastEnabled = true);
        
        update currentUser;
    }*/

    @isTest(SeeAllData=true)
    static void testTargets() {
        Test.startTest();
        
        Set<Id> periodIDs = new Set<Id>(SalesTargetController.GetMonthPeriods());
        
        // NOTE: Inserting RevenueForecast records during the test is proving unreliable.
        // Going to comment out all the code below and rely on creating appropriate test data in the system.
        
        /*System.debug('Period IDs: ' + periodIDs);
        
        Map<Id, Period> periodMap = new Map<Id, Period>([SELECT Id, Number, StartDate FROM Period WHERE Id IN :periodIDs]);
        
        System.debug('Periods: ' + periodMap.values());
        
        Set<Date> startDates = new Set<Date>();
        
        for (Period p: periodMap.values()) {
            startDates.add(p.StartDate);
        }
        
        System.debug('Start Dates: ' + startDates);
        
        List<RevenueForecast> digitals = [SELECT Id, PeriodId, StartDate, ProductFamily, Quota FROM RevenueForecast WHERE (OwnerId = :UserInfo.getUserId()) AND (ProductFamily = 'Digital') AND (StartDate IN :startDates)];
        
        System.debug('Existing: ' + digitals);
        
        Set<Id> forecastPeriods = new Set<Id>(periodIDs);
        
        for (RevenueForecast digital : digitals) {
            if (forecastPeriods.contains(digital.PeriodId)) {
                digital.Quota = 100;
                forecastPeriods.remove(digital.PeriodId);
            }
        }
        
        update digitals;
        
        System.debug('Remaining: ' + forecastPeriods);
        
        if (!forecastPeriods.isEmpty()) {
            List<RevenueForecast> newForecasts = new List<RevenueForecast>();
            
            for (Id pId: forecastPeriods) {
                Period p = periodMap.get(pId);
                
                newForecasts.add(new RevenueForecast(StartDate = p.StartDate, ProductFamily = 'Digital', Quota = 100, OwnerId = UserInfo.getUserId()));
            }
            
            System.debug('New: ' + newForecasts);
            
            insert newForecasts;
        }*/
        
        /*RevenueForecast digital1 = new RevenueForecast(StartDate = periods[0].StartDate, ProductFamily = 'Digital', Quota = 100);
        RevenueForecast digital2 = new RevenueForecast(StartDate = periods[1].StartDate, ProductFamily = 'Digital', Quota = 100);
        RevenueForecast digital3 = new RevenueForecast(StartDate = periods[2].StartDate, ProductFamily = 'Digital', Quota = 100);
        
        insert digital1;
        insert digital2;
        insert digital3;*/
        
        /*RevenueForecast print1 = new RevenueForecast(StartDate = periods[0].StartDate, ProductFamily = 'Print', Quota = 100);
        RevenueForecast print2 = new RevenueForecast(StartDate = periods[1].StartDate, ProductFamily = 'Print', Quota = 100);
        RevenueForecast print3 = new RevenueForecast(StartDate = periods[2].StartDate, ProductFamily = 'Print', Quota = 100);
        
        insert print1;
        insert print2;
        insert print3;*/
        
        List<RevenueForecast> forecasts = [Select Id, OwnerId From RevenueForecast Where (PeriodId IN :periodIDs) AND (ProductFamily IN ('Digital','Print')) AND (Quota != null)];
        
        SalesTargetController.getRevenueForecast(forecasts[0].OwnerId);
        
        Test.stopTest();
    }
}