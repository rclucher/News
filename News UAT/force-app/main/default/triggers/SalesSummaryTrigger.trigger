trigger SalesSummaryTrigger on SalesSummary__c (before insert, before update) {
    
    SalesSummaryTriggerHandler utility = new SalesSummaryTriggerHandler();

    //generate the month
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        utility.populateFiscalInformation();
    }

    //validate the external id
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        utility.validateExternalId();
    }
}