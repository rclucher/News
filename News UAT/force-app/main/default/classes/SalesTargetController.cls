/**
* @description  Controller used for Lightning component SalesTarget.cmp for the server-side
*
* @author       Paul Kang
* @date         2018-01-16
*
* @author       Pratyush Chalasani
* @date         2018-02-01
**/

public without sharing class SalesTargetController {
    
    private static Integer numberOfMonths = 3;

    @AuraEnabled
    public static List<Id> getMonthPeriods() {
        return getMonthPeriods(numberOfMonths);
    }
    
    @AuraEnabled
    public static List<Id> getMonthPeriods(Integer monthCount) {
        Integer month = System.Today().month();
        
        List<Integer> currentMonths = new List<Integer>();
        List<Integer> nextMonths = new List<Integer>();
        List<Integer> previousMonths = new List<Integer>();
            
        if (month < 7) {
            month += 6;
        } else {
            month -= 6;
        }
        
        if (monthCount > 0) {
            for (Integer m = 0; m < monthCount; m++) {
                currentMonths.add(month);
                
                month++;
                
                if (month > 12) break;
            }
    
            if (currentMonths.size() < monthCount) {
                for (Integer m = 1; m <= (monthCount - currentMonths.size()); m++) {
                    nextMonths.add(m);
                }
            }
        } else {
            monthCount = -monthCount;
            
            if (month > 1) {
                month--;
                
                for (Integer m = 0; m < monthCount; m++) {
                    currentMonths.add(month);
                    
                    if (month == 1) break;
                    
                    month--;
                }
            } else {
                month = 12;
            }

            if (currentMonths.size() < monthCount) {
                for (Integer m = 12; m > (12 - monthCount + currentMonths.size()); m--) {
                    previousMonths.add(m);
                }
            }
        }
        
          //Get all the Periods from Current month onwards
        List<Id> periodIDs = new List<Id>();

        if (!currentMonths.isEmpty()) {
            for( Period p: ([SELECT Id, Number FROM Period
                            where type = 'Month' and startdate = THIS_FISCAL_YEAR and IsForecastPeriod = true and Number IN :currentMonths
                            order by startdate])) {
                    
                    periodIDs.add(p.Id);
            }
        }
        
        if (!nextMonths.isEmpty()) {
            for( Period p: ([SELECT Id, Number FROM Period
                            where type = 'Month' and startdate = NEXT_FISCAL_YEAR and IsForecastPeriod = true and Number IN :nextMonths
                            order by startdate])) {
                    
                    periodIDs.add(p.Id);
            }
        }
        
        if (!previousMonths.isEmpty()) {
            for( Period p: ([SELECT Id, Number FROM Period
                            where type = 'Month' and startdate = LAST_FISCAL_YEAR and IsForecastPeriod = true and Number IN :previousMonths
                            order by startdate])) {
                    
                    periodIDs.add(p.Id);
            }
        }

        System.debug('Period IDs: ' + periodIDs);
        return periodIDs;
    }

    private static Map<Id, Integer> getPeriodMonths(List<Id> periodIDs) {
        Map<Id, Integer> monthMap = new Map<Id, Integer>();
        
        for (Period p: [SELECT Id, Number FROM Period WHERE Id IN: periodIDs]) {
            monthMap.put(p.Id, p.Number);
        }
        
        return monthMap;
    }
   
    @AuraEnabled
    public static SalesTargetResponse getRevenueForecast(Id ownerId) {
        return getRevenueForecast(ownerId, new Set<Id>(), numberOfMonths);
    }
    
    public static SalesTargetResponse getRevenueForecast(Id ownerId, Set<Id> roleIDs, Integer monthCount) {
        Map<Integer,String> monthNames = new Map<Integer,String>();
        monthNames.put(1, 'July');
        monthNames.put(2, 'August');
        monthNames.put(3, 'September');
        monthNames.put(4, 'October');
        monthNames.put(5, 'November');
        monthNames.put(6, 'December');
        monthNames.put(7, 'January');
        monthNames.put(8, 'February');
        monthNames.put(9, 'March');
        monthNames.put(10, 'April');
        monthNames.put(11, 'May');
        monthNames.put(12, 'June');
        
        SalesTargetResponse response = new SalesTargetResponse();
        
        List<Id> periodIDs = getMonthPeriods(monthCount);
        
        Map<Id, Integer> monthMap = getPeriodMonths(periodIDs);
 
        List<AggregateResult> revenueList = [Select PeriodId, ProductFamily, SUM(Quota) 
                                                From RevenueForecast where ((OwnerId=:ownerId) OR (Owner.UserRoleId IN :roleIDs)) and PeriodId IN :periodIDs AND ProductFamily IN ('Digital','Print') 
                                                GROUP BY PeriodId, ProductFamily ORDER BY PeriodId];
        
        System.debug('@aggregate result ' + revenueList);

        Map<String, SalesTarget> targetMap = new Map<String, SalesTarget>();
        
        for(AggregateResult forecast : revenueList) {
            if (forecast.get('expr0') != null) {
                String  ProductFamily = (String)forecast.get('ProductFamily');
                String  PeriodId = (String)forecast.get('PeriodId');
                Integer monthNumber = monthMap.get(PeriodId);
                String  MonthName =monthNames.get(monthNumber);
                Decimal Quota = (Decimal)forecast.get('expr0');
                
                SalesTarget target = targetMap.get(MonthName);
                
                if (target == null) target = new SalesTarget();
                
                if (ProductFamily.startsWithIgnoreCase('Digital')) target.Digital += (Integer)Quota;

                if (ProductFamily.startsWithIgnoreCase('Print')) target.Print += (Integer)Quota;
                
                target.Combined += (Integer)Quota;
                response.Total += Quota;
                
                target.Month = MonthName;
                target.MonthNumber = monthNumber;
                
                target.periodID = PeriodId;
                
                targetMap.put(MonthName, target);
            }
        }

        List<SalesTarget> targets = new List<SalesTarget>();
        
        for (Id pId: periodIDs) targets.add(targetMap.get(monthNames.get(monthMap.get(pId))));
        
		response.targets = targets;
        
        return response;
    }
    
    public class SalesTargetResponse {
        @AuraEnabled
        public List<SalesTarget> targets {get; set;}
        
        @AuraEnabled
        public Decimal Total {get; set;}
        
        public SalesTargetResponse() {
            targets = new List<SalesTarget>();
            Total = 0;
        }
    }
    
    public class SalesTarget {
        @AuraEnabled
        public Integer MonthNumber {get; set;}
        
        @AuraEnabled
        public String Month {get; set;}
        
        @AuraEnabled
        public Integer digital {get; set;}
        
        @AuraEnabled
        public Integer print {get; set;}
        
        @AuraEnabled
        public Integer combined {get; set;}
        
        @AuraEnabled
        public String periodID {get; set;}
        
        public SalesTarget() {
            this.MonthNumber = 0;
            this.Month = '';
            this.Digital = 0;
            this.Print = 0;
            this.Combined = 0;
            this.periodID = '';
        }
    }
    
}