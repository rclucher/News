public class SalesSummaryStagingCleanUpSCHED implements Schedulable {
   public void execute(SchedulableContext sc) {
       Date delOlder = system.Today() - 5; 
       List<SalesSummaryStaging__c> sssDeleteList = new List<SalesSummaryStaging__c>([SELECT Id FROM SalesSummaryStaging__c WHERE CreatedDate <= :delOlder]);
       if(!sssDeleteList.isEmpty()){
           try{delete sssDeleteList;}catch(Exception e){ExLog.log(e, 'config', sssDeleteList, 'From SalesSummaryStagingCleanUpSCHED.execute().');  
               system.debug('##Could not delete Sales Summary Staging records ' + sssDeleteList);           
           }
       }
   }
}