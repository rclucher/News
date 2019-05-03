trigger SOTriggerNewsXtend on csmso__Sales_Order__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    system.debug('Sales Order Trigger');
    if(Trigger.isInsert && Trigger.isAfter){
        SOTriggerNewsXtendHelper.AddPackageInsert(Trigger.New);
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        SOTriggerNewsXtendHelper.AddPackageUpdate(Trigger.New);
    }
}