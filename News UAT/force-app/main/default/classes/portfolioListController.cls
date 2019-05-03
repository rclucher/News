public class portfolioListController{

    public class PortfolioData{
        //Map of Account portfolios and Ad Point number
        @AuraEnabled
        public Map<String,Set<String>> accPortfolios {get;set;}
        
        //Map of Booking System portfolios and booking systems account number.
        @AuraEnabled
        public Map<String,Set<String>> bookingSystemPortfolios {get;set;}
        
        @AuraEnabled
        public List<Portfolio2__c> portfolioList {get;set;} 
        
        public PortfolioData() {
            //accPortfolios = new Map<Id,Set<String>>();
            //bookingSystemPortfolios = new Map<Id,Set<String>>();
            portfolioList = new List<Portfolio2__c>();
        }
    }
    
    @AuraEnabled
    public static PortfolioData getPortfolios(Id recordId){
        
        PortfolioData pd = new PortfolioData();
        
        StringMapSet accPortfolios = new StringMapSet();
        StringMapSet bookingSystemPortfolios = new StringMapSet();
        
        for (Account_Portfolio_Relationship__c apr: [SELECT Portfolio__c, Account__r.AdPoint_Id__c FROM Account_Portfolio_Relationship__c WHERE Account__c = :recordId]) {
            accPortfolios.add(apr.Portfolio__c, apr.Account__r.AdPoint_Id__c);
        }
        system.debug('--Acc Portfolios Map: '+ accPortfolios.keySetMap);

        for (Booking_System_Portfolio_Junction__c bspj: [SELECT Portfolio__c,Booking_System_Account__r.Account_No__c FROM Booking_System_Portfolio_Junction__c WHERE Booking_System_Account__c IN (SELECT Id FROM External_Account__c WHERE Customer_Account__c = :recordId)]) {
            bookingSystemPortfolios.add(bspj.Portfolio__c, bspj.Booking_System_Account__r.Account_No__c);
        }
        system.debug('--Booking System Portfolios Map: ' + bookingSystemPortfolios.keySetMap);
        pd.portfolioList = [SELECT Id, Name, (SELECT Portfolio_Owner__c, Portfolio_Owner__r.Name FROM Portfolio_Teams__r) FROM Portfolio2__c WHERE Id IN :accPortfolios.keySet() OR Id IN :bookingSystemPortfolios.keySet()];
        system.debug('**Portfolio List'+ pd.portfolioList);
        system.debug('**The Class Instance' +pd);
        
        pd.accPortfolios = accPortfolios.keySetMap;
        pd.bookingSystemPortfolios = bookingSystemPortfolios.keySetMap;
        
        return pd;
   }
}