//NR-1930 adding support from all trigger events (leaving out undelete)
trigger CS_ProductConfigurationTrigger on cscfga__Product_Configuration__c (before insert, after insert, before update, after update, before delete, after delete)  {
	
	CS_TriggerHandler.execute(new CS_ProductConfigurationTriggerDelegate());
}