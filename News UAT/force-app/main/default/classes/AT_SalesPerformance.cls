public class AT_SalesPerformance {
    private static final Integer lowestProbability = 30;
    private static final Integer highestProbability = 100;
    
    // Mapping of calendar month to FY months for the corresponding FY quarter
    private static final Map<Integer, List<Integer>> monthQuarters = new Map<Integer, List<Integer>>{
        1 => new List<Integer>{7, 8, 9},
        2 => new List<Integer>{7, 8, 9},
        3 => new List<Integer>{7, 8, 9},
        4 => new List<Integer>{10, 11, 12},
        5 => new List<Integer>{10, 11, 12},
        6 => new List<Integer>{10, 11, 12},
        7 => new List<Integer>{1, 2, 3},
        8 => new List<Integer>{1, 2, 3},
        9 => new List<Integer>{1, 2, 3},
        10 => new List<Integer>{4, 5, 6},
        11 => new List<Integer>{4, 5, 6},
        12 => new List<Integer>{4, 5, 6}
    };
        
    private static Map<Integer, String> monthNames = new Map<Integer, String>{
        1 => 'July',
        2 => 'August',
        3 => 'September',
        4 => 'October',
        5 => 'November',
        6 => 'December',
        7 => 'January',
        8 => 'February',
        9 => 'March',
        10 => 'April',
        11 => 'May',
        12 => 'June'
    };
        
    public static Map<Id, Integer> getPeriodMonths(List<Id> periodIDs) {
        Map<Id, Integer> monthMap = new Map<Id, Integer>();
        
        for (Period p: [SELECT Id, Number FROM Period WHERE Id IN: periodIDs]) {
            monthMap.put(p.Id, p.Number);
        }
        
        return monthMap;
    }
    
    public class MonthPeriod {
        @AuraEnabled
        public String periodID {get; set;}
        
        @AuraEnabled
        public Integer month {get; set;}
        
        @AuraEnabled
        public String monthName {get; set;}
        
        @AuraEnabled
        public Date startDate {get; set;}
        
        public MonthPeriod(String periodID, Integer month, Date startDate) {
            this.periodID = periodID;
            this.month = month;
            this.monthName = monthNames.get(month);
            this.startDate = startDate;
        }
    }

    @AuraEnabled
    public static List<MonthPeriod> getCurrentAndNextPeriods(Integer nextCount) {
        Integer numberOfMonths = 1 + Integer.valueOf(nextCount);
        
        Integer month = System.Today().month();
        
        if (month < 7) {
            month += 6;
        } else {
            month -= 6;
        }
        
        List<Integer> currentMonths = new List<Integer>();
        List<Integer> nextMonths = new List<Integer>();
        
        for (Integer m = 0; m < numberOfMonths; m++) {
            currentMonths.add(month);
            
            month++;
            
            if (month > 12) break;
        }

        if (currentMonths.size() < numberOfMonths) {
            for (Integer m = 1; m <= (numberOfMonths - currentMonths.size()); m++) {
                nextMonths.add(m);
            }
        }
        
        //Get all the Periods from Current month onwards
        List<MonthPeriod> monthPeriods = new List<MonthPeriod>();

        if (!currentMonths.isEmpty()) {
            for( Period p: ([SELECT Id, Number,StartDate FROM Period
                            where type = 'Month' and startdate = THIS_FISCAL_YEAR and IsForecastPeriod = true and Number IN :currentMonths
                            order by startdate])) {
                    
                    monthPeriods.add(new MonthPeriod(p.Id, p.Number, p.StartDate));
            }
        }
        
        if (!nextMonths.isEmpty()) {
            for( Period p: ([SELECT Id, Number, StartDate FROM Period
                            where type = 'Month' and startdate = NEXT_FISCAL_YEAR and IsForecastPeriod = true and Number IN :nextMonths
                            order by startdate])) {
                    
                    monthPeriods.add(new MonthPeriod(p.Id, p.Number, p.StartDate));
            }
        }

        return monthPeriods;
    }
        
    @AuraEnabled
    public static List<MonthPeriod> getFYQuarterPeriods() {
        Integer month = System.Today().month();
        
        List<Integer> fyMonths = monthQuarters.get(month);
        
        List<MonthPeriod> monthPeriods = new List<MonthPeriod>();

        for( Period p: ([SELECT Id, Number, StartDate FROM Period
                         where type = 'Month' and startdate = THIS_FISCAL_YEAR and IsForecastPeriod = true and Number IN :fyMonths
                         order by startdate])) {
                             
                             monthPeriods.add(new MonthPeriod(p.Id, p.Number, p.StartDate));
                         }
        
        return monthPeriods;
    }
        
    public class Sales {
        @AuraEnabled
        public Decimal print {get; set;}
        @AuraEnabled
        public Decimal digital {get; set;}
        @AuraEnabled
        public Decimal combined {get; set;}
        
        public Sales() {
            print    = 0;
            digital  = 0;
            combined = 0;
        }
    }
    
    @AuraEnabled
    public static List<Sales> getSalesActualsForPeriods(List<Id> periodIDs) {
        return getSalesActualsForPeriods(periodIDs, UserInfo.getUserId(), AT_AccessUtil.getCurrentUserRoleAndSubordinates());
    }
    
    public static List<Sales> getSalesActualsForPeriods(List<Id> periodIDs, Id userID, Set<Id> roleIDs) {
        Map<String, Sales> periodSales = new Map<String, Sales>();
                
        Map<String, Date> periodProductDate = new Map<String, Date>();
        
        for (String periodID: periodIDs) {
            for (Sales_Actuals__c sa: [SELECT PeriodId__c, Product_Family__c, Date__c, Amount__c, CreatedDate FROM Sales_Actuals__c WHERE ((OwnerId = :useRID) OR (Owner.UserRoleId IN :roleIDs)) AND (PeriodId__c = :periodID) ORDER BY Date__c ASC]) {
                String productFamily = sa.Product_Family__c.startsWithIgnoreCase('Print') ? 'Print' : (sa.Product_Family__c.startsWithIgnoreCase('Digital') ? 'Digital' : '');
                
                Date latestDate = periodProductDate.get(sa.PeriodId__c + ':' + productFamily);
                
                if ((latestDate != null) && (sa.Date__c < latestDate)) continue;
                
                periodProductDate.put(sa.PeriodId__c + ':' + productFamily, sa.Date__c);
                
                Sales s = periodSales.get(periodID);
                
                if (s == null) s = new Sales();
                    
                if (sa.Product_Family__c.startsWithIgnoreCase('Print') && (sa.Amount__c != null)) s.print += sa.Amount__c;
                if (sa.Product_Family__c.startsWithIgnoreCase('Digital') && (sa.Amount__c != null)) s.digital += sa.Amount__c;
                if (sa.Amount__c != null) s.combined += sa.Amount__c;
                
                periodSales.put(periodID, s);
            }
        }
        
        List<Sales> sales = new List<Sales>();
        
        for (String periodID: periodIDs) {
            Sales actual = periodSales.get(periodID);
            
            if (actual == null) actual = new Sales();
            
            sales.add(actual);
        }
        
        return sales;
    }
    
    @AuraEnabled
    public static List<Sales> getPipelineForPeriods(List<Id> periodIDs) {
        List<Sales> sales = new List<Sales>();

        Set<Id> roleIDs = AT_AccessUtil.getCurrentUserRoleAndSubordinates();
        
        List<Period> periods = [SELECT Id, StartDate, EndDate FROM Period WHERE Id IN :periodIDs ORDER BY StartDate ASC, EndDate ASC];
        
        Date earliestStart = periods[0].StartDate;
        Date latestEnd     = periods[periods.size() - 1].EndDate;
        
        Map<Id, Period> periodMap = new Map<Id, Period>();
        
        for (Period p: periods) periodMap.put(p.Id, p);
        
        List<OpportunityLineItemSchedule> revenueSchedules = [SELECT ScheduleDate, OpportunityLineItem.OpportunityId, OpportunityLineItem.Opportunity.Probability, OpportunityLineItem.Product2.Family, Revenue FROM OpportunityLineItemSchedule WHERE (ScheduleDate >= :earliestStart) AND (ScheduleDate <= :latestEnd) AND (OpportunityLineItem.Opportunity.IsClosed = false) AND (OpportunityLineItem.Opportunity.Probability >= :lowestProbability) AND (OpportunityLineItem.Opportunity.Probability < :highestProbability) AND ((OpportunityLineItem.Opportunity.OwnerId = :UserInfo.getUserId()) OR (OpportunityLineItem.Opportunity.Owner.UserRoleId IN :roleIDs))];
        
        Set<Id> oppsWithRevSchedule = new Set<Id>();
        
        for (OpportunityLineItemSchedule rs: revenueSchedules) oppsWithRevSchedule.add(rs.OpportunityLineItem.OpportunityId);
        
        for (String periodID: periodIDs) {
            Period prd = periodMap.get(periodID);
            
            Sales s = new Sales();
            
            //for (OpportunityLineItemSchedule rev: [SELECT OpportunityLineItem.OpportunityId, OpportunityLineItem.Opportunity.Probability, OpportunityLineItem.Product2.Family, Revenue FROM OpportunityLineItemSchedule WHERE (ScheduleDate >= :prd.StartDate) AND (ScheduleDate <= :prd.StartDate) AND (OpportunityLineItem.Opportunity.IsClosed = false) AND (OpportunityLineItem.Opportunity.Probability >= :lowestProbability) AND (OpportunityLineItem.Opportunity.Probability < :highestProbability) AND ((OpportunityLineItem.Opportunity.OwnerId = :UserInfo.getUserId()) OR (OpportunityLineItem.Opportunity.Owner.UserRoleId IN :roleIDs))]) {
            //    oppsWithRevSchedule.add(rev.OpportunityLineItem.OpportunityId);
            for (OpportunityLineItemSchedule rev: revenueSchedules) {  
                if ((rev.ScheduleDate >= prd.StartDate) && (rev.ScheduleDate <= prd.EndDate)) {
                    Decimal weight = rev.OpportunityLineItem.Opportunity.Probability / 100.0;
                    
                    if (rev.OpportunityLineItem.Product2.Family.startsWith('Digital')) {
                        s.digital += (rev.Revenue * weight);
                    } else if (rev.OpportunityLineItem.Product2.Family.startsWith('Print')) {
                        s.print += (rev.Revenue * weight);
                    }
                    
                    s.combined += (rev.Revenue * weight);
                }
            }
            
            //SELECT Opportunity.Name, Opportunity.CloseDate, UnitPrice, Opportunity.Probability, Product2.Name, Product2.Family FROM OpportunityLineItem WHERE (OpportunityId NOT IN :oppsWithRevSchedule) AND (Opportunity.IsClosed = false) AND (((Opportunity.Schedule_Date_Earliest__c != null) AND (Opportunity.Schedule_Date_Earliest__c  >= :prd.StartDate) AND (Opportunity.Schedule_Date_Earliest__c <= :prd.EndDate)) OR ((Opportunity.Campaign_Start_Date__c  >= :prd.StartDate) AND (Opportunity.Campaign_Start_Date__c <= :prd.EndDate))) AND (Opportunity.Probability >= :lowestProbability) AND (Opportunity.Probability < :highestProbability) AND ((Opportunity.OwnerId = :UserInfo.getUserId()) OR (Opportunity.Owner.UserRoleId IN :roleIDs))]
            for (OpportunityLineItem item: [SELECT Opportunity.Name, Opportunity.CloseDate, UnitPrice, Opportunity.Probability, Product2.Name, Product2.Family FROM OpportunityLineItem WHERE (OpportunityId NOT IN :oppsWithRevSchedule) AND (Opportunity.IsClosed = false) AND ((Opportunity.Campaign_Start_Date__c != null) AND (Opportunity.Campaign_Start_Date__c  >= :prd.StartDate) AND (Opportunity.Campaign_Start_Date__c <= :prd.EndDate)) AND (Opportunity.Probability >= :lowestProbability) AND (Opportunity.Probability < :highestProbability) AND ((Opportunity.OwnerId = :UserInfo.getUserId()) OR (Opportunity.Owner.UserRoleId IN :roleIDs))]) {
                Decimal weight = item.Opportunity.Probability / 100.0;
                
                if (item.Product2.Family.startsWith('Digital')) {
                    s.digital += (item.UnitPrice * weight);
                } else if (item.Product2.Family.startsWith('Print')) {
                    s.print += (item.UnitPrice * weight);
                }
                
                s.combined += (item.UnitPrice * weight);
            }
            
            s.print = Math.round(s.print);
            s.digital = Math.round(s.digital);
            s.combined = Math.round(s.combined);
            
            sales.add(s);
        }
            
        return sales;
    }
    
    @AuraEnabled
    public static List<Sales> getTargetsForPeriods(List<Id> periodIDs) {
        Set<Id> roleIDs = AT_AccessUtil.getCurrentUserRoleAndSubordinates();
        
        List<AggregateResult> forecasts = [SELECT PeriodId, ProductFamily, SUM(Quota) total
                                             FROM RevenueForecast
                                             WHERE (OwnerId = :UserInfo.getUserId())  AND
                                                   PeriodId IN :periodIDs AND
                                                   ProductFamily IN ('Digital','Print') 
                                             GROUP BY PeriodId, ProductFamily];
        
        //((OwnerId = :UserInfo.getUserId()) OR (Owner.UserRoleId IN :roleIDs)) 
        
        //System.debug('@aggregate result ' + forecasts);

        Map<String, Sales> periodForecasts = new Map<String, Sales>();
        
        for(AggregateResult forecast: forecasts) {
            if (forecast.get('total') != null) {
                String  product = (String)forecast.get('ProductFamily');
                String  period = (String)forecast.get('PeriodId');
                Decimal quota = (Decimal)forecast.get('total');
                
                Sales target = periodForecasts.get(period);
                
                if (target == null) target = new Sales();
                
                if (product.equalsIgnoreCase('Digital')) target.digital += (Integer)quota;
                if (product.equalsIgnoreCase('Print')) target.print += (Integer)quota;
                
                target.combined += (Integer)quota;
                
                periodForecasts.put(period, target);
            }
        }

        List<Sales> targets = new List<Sales>();
        
        for (Id periodID: periodIDs) {
            Sales target = periodForecasts.get(periodID);
            
            if (target == null) target = new Sales();
                
            targets.add(target);
        }
        
        return targets;
    }
}