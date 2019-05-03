trigger CS_OrderTrigger on Order__c (
  before insert, 
  before update, 
  before delete, 
  after insert, 
  after update, 
  after delete, 
  after undelete) 
  { CS_TriggerHandler.execute(new CS_OrderTriggerDelegate()); }