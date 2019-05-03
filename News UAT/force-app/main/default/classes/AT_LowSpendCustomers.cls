public class AT_LowSpendCustomers {
    public class AccountSpend implements Comparable {
        @AuraEnabled
        public Id Id {get; set;}
        @AuraEnabled
        public String Name {get; set;}
        @AuraEnabled
        public String Link {get; set;}
        @AuraEnabled
        public Decimal CurrentFY {get; set;}
        @AuraEnabled
        public Decimal PreviousFY {get; set;}
        @AuraEnabled
        public Decimal Difference {get; set;}
        
        public Integer compareTo(Object to) {
            AccountSpend other = (AccountSpend)to;
            
            if (this.Difference > other.Difference) {
                return -1;
            } else if (this.Difference < other.Difference) {
                return 1;
            } else {
                return 0;
            }
        }
    }    
    
    @AuraEnabled
    public static List<AccountSpend> getSpending(Id ownerID, Integer count) {
        Integer max = Integer.valueOf(count);
        
        //List<String> recordTypeNames = new List<String>{'IMA_Independent_Agencies','IMA_Major_Account','KAC_Consortium','KAC_Key_Account','IMA','KAC','Real_Estate','SME','The_Aus_Regional'};
        Set<String> accountTypes =  new Set<String>();
        
        for (NextGen_Account_Type__mdt accType: [SELECT DeveloperName FROM NextGen_Account_Type__mdt]) {
            accountTypes.add(accType.DeveloperName);
        }
        
        List<RecordType> accountRTs = [SELECT Id FROM RecordType WHERE (SObjectType = 'Account') AND (DeveloperName IN :accountTypes)];
            
        Set<Id> roleIDs = AT_AccessUtil.getCurrentUserRoleAndSubordinates();
        
        //List<Account> accs = [SELECT Id, Name FROM Account WHERE (OwnerId = :ownerID) OR (Owner.UserRoleId IN :roleIDs)];

        Integer currentMonth = System.today().month();
        
        List<AggregateResult> lastOpps;
        
        List<AggregateResult> currentOpps;
        
        //System.debug('Current month: ' + currentMonth);
        
        Set<Id> accountIDs = new Set<Id>();
        
        if (currentMonth >= 7) {
            currentOpps = [SELECT AccountId, SUM(Amount) total FROM Opportunity WHERE (CloseDate = THIS_FISCAL_YEAR) AND (CALENDAR_MONTH(CloseDate) <= :currentMonth) AND (AccountId IN (SELECT Id FROM Account WHERE (RecordTypeId IN :accountRTs) AND (Status__c = 'Active') AND ((OwnerId = :ownerID) OR (Owner.UserRoleId IN :roleIDs)))) GROUP BY AccountId];
            
            //System.debug('Current FY Opps: ' + currentOpps.size());
            
            for (AggregateResult agg: currentOpps) accountIDs.add((Id)agg.get('AccountId'));
        	
            lastOpps = [SELECT AccountId, SUM(Amount) total FROM Opportunity WHERE (AccountId IN :accountIDs) AND (CloseDate = LAST_FISCAL_YEAR) AND (CALENDAR_MONTH(CloseDate) <= :currentMonth) GROUP BY AccountId];
            
            //System.debug('Last FY Opps: ' + lastOpps.size());
        } else {
            currentOpps = [SELECT AccountId, SUM(Amount) total FROM Opportunity WHERE (AccountId IN (SELECT Id FROM Account WHERE (RecordTypeId IN :accountRTs) AND (Status__c = 'Active') AND ((OwnerId = :ownerID) OR (Owner.UserRoleId IN :roleIDs)))) AND (CloseDate = THIS_FISCAL_YEAR) AND ((CALENDAR_MONTH(CloseDate) >= 7) OR (CALENDAR_MONTH(CloseDate) <= :currentMonth)) GROUP BY AccountId];
            
            //System.debug('Current FY Opps: ' + currentOpps.size());
            
            for (AggregateResult agg: currentOpps) accountIDs.add((Id)agg.get('AccountId'));
            
            lastOpps = [SELECT AccountId, SUM(Amount) total FROM Opportunity WHERE (AccountId IN :accountIDs) AND (CloseDate = LAST_FISCAL_YEAR) AND ((CALENDAR_MONTH(CloseDate) >= 7) OR (CALENDAR_MONTH(CloseDate) <= :currentMonth)) GROUP BY AccountId];
            
            //System.debug('Last FY Opps: ' + lastOpps.size());
        }
        
        //if ((lastOpps != null) && !lastOpps.isEmpty()) for (AggregateResult agg: lastOpps) https://newscorpaustralia--adsalesuat.cs58.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#
        
        //if ((currentOpps != null) && !currentOpps.isEmpty()) for (AggregateResult agg: currentOpps) accountIDs.add((Id)opp.get('AccountId'));
        
        /*if (currentMonth >= 7) {
            lastOpps = [SELECT AccountId, Account.Name, SUM(Amount) total FROM Opportunity WHERE (AccountId IN :accs) AND (CloseDate = LAST_FISCAL_YEAR) AND (CALENDAR_MONTH(CloseDate) <= :currentMonth) GROUP BY AccountId];
            currentOpps = [SELECT AccountId, Account.Name, SUM(Amount) total FROM Opportunity WHERE (AccountId IN :accs) AND (CloseDate = THIS_FISCAL_YEAR) AND (CALENDAR_MONTH(CloseDate) <= :currentMonth) GROUP BY AccountId];
        } else {
            lastOpps = [SELECT AccountId, Account.Name, SUM(Amount) total FROM Opportunity WHERE (AccountId IN :accs) AND (CloseDate = LAST_FISCAL_YEAR) AND ((CALENDAR_MONTH(CloseDate) >= 7) OR (CALENDAR_MONTH(CloseDate) <= :currentMonth)) GROUP BY AccountId];
            currentOpps = [SELECT AccountId, Account.Name, SUM(Amount) total FROM Opportunity WHERE (AccountId IN :accs) AND (CloseDate = THIS_FISCAL_YEAR) AND ((CALENDAR_MONTH(CloseDate) >= 7) OR (CALENDAR_MONTH(CloseDate) <= :currentMonth)) GROUP BY AccountId];
        }*/

		//
        
        Map<Id, Decimal> lastSpend = new Map<Id, Decimal>();
        Map<Id, Decimal> currentSpend = new Map<Id, Decimal>();
        
        for (AggregateResult agg: lastOpps) {
            lastSpend.put((Id)agg.get('AccountId'), (Decimal)agg.get('total'));
            //accountIDs.add((Id)agg.get('AccountId'));
        }
        
        for (AggregateResult agg: currentOpps) {
            currentSpend.put((Id)agg.get('AccountId'), (Decimal)agg.get('total'));
            //accountIDs.add((Id)agg.get('AccountId'));
        }
        
        List<AccountSpend> spending = new List<AccountSpend>();
        
        for (Account acc: [SELECT Id, Name FROM Account WHERE (Id IN :accountIDs)]) {
            Decimal last = lastSpend.get(acc.Id);
            Decimal current = currentSpend.get(acc.Id);

            if (last == null) last = 0.0;
            if (current == null) current = 0.0;
            
            if (last > current) {
                AccountSpend spend = new AccountSpend();
                    
                spend.Id    = acc.Id;
                spend.Name  = acc.Name;
                spend.Link  = '/' + acc.Id;
                spend.Difference = last - current;
                spend.PreviousFY = last;
                spend.CurrentFY = current;
                    
                spending.add(spend);
            }
        }
        
        spending.sort();
        
        List<AccountSpend> selected = new List<AccountSpend>();
        
        Integer total = (spending.size() > max) ? max : spending.size();
        
        for (Integer i = 0; i < total; i++) selected.add(spending[i]);

        return selected;
    }
}