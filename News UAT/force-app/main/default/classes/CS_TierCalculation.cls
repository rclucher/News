public class CS_TierCalculation {
  public static void setAccountTierFor (List<Payment_Schedule__c> paymentSchedules) {
    Map<Id, Account> accountsForUpdate = new Map<Id, Account>();

    Map<Id, Decimal> monthInvoicePerAccount = new Map<Id, Decimal>();
    system.debug(paymentSchedules.size());
      for (Payment_Schedule__c paySchedule : paymentSchedules) {
        Decimal sumMonth = monthInvoicePerAccount.get(paySchedule.Payment__r.order__r.Opportunity__r.accountid);
        if (sumMonth == null) {
          sumMonth = 0;
        }
        sumMonth += paySchedule.Amount__c;
            system.debug(sumMonth);
system.debug(paySchedule.Payment__r.order__r.Opportunity__r.accountid);

        if (paySchedule.Payment__r.order__r.Opportunity__r.accountid != null) 
          monthInvoicePerAccount.put(paySchedule.Payment__r.order__r.Opportunity__r.accountid, sumMonth);
          
      }
system.debug(monthInvoicePerAccount);
      accountsForUpdate = new Map<Id, Account>([SELECT Id, Tier__c, Name from Account WHERE Id IN: monthInvoicePerAccount.keySet()]);

      for (Id accountId : monthInvoicePerAccount.keySet()) {
        if (accountsForUpdate.get(accountId) != null) {
          Decimal monthInvoice = monthInvoicePerAccount.get(accountId);

          List<Customer_Tier_Ranges__c> tierRanges = Customer_Tier_Ranges__c.getall().values();
          
          for (Customer_Tier_Ranges__c tierRange: tierRanges)
          {             
            if ((monthInvoice != null) && (monthInvoice >= tierRange.Lowerbound__c) && (monthInvoice <= tierRange.Upperbound__c))
            {
              accountsForUpdate.get(accountId).Tier__c = tierRange.Name;
            }
          }
        }
      }
      try {

        update accountsForUpdate.values();
      } catch(Exception ex)
        {
            ExLog.log(ex, 'config', accountsForUpdate.values(), 'Could not update accountidount tiers.');
        }

      List<order__c> campaigns = [select id, Customer_Tier__c,Account__c from order__c where account__c in: accountsForUpdate.keySet() and Overall_Status__c = 'Active'];

      for (order__c campaign : campaigns) {
        if (accountsForUpdate.get(campaign.Account__c).Tier__c != null && accountsForUpdate.get(campaign.Account__c).Tier__c != '')
          campaign.Customer_Tier__c = accountsForUpdate.get(campaign.Account__c).Tier__c;
      }
      try {
        update campaigns;
     } catch(Exception ex)
        {
            ExLog.log(ex, 'config', campaigns, 'Could not update campaign tiers.');
        }
  }
}