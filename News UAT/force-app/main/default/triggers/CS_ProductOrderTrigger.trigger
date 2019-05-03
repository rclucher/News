trigger CS_ProductOrderTrigger on Product_Order__c  (before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete) { CS_TriggerHandler.execute(new CS_ProductOrderTriggerDelegate());
}