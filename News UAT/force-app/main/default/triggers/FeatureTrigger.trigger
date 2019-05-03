/**
* @company      Bluewolf
* @author       Noel Lim (noel.lim@bluewolf.com)
* @date         21/11/2014
* @description  Feature Trigger using the Handler pattern 
*/
trigger FeatureTrigger on Feature__c (after delete, after insert, after undelete, 
                               after update, before delete, before insert, 
                               before update) {
    
    FeatureTriggerHandler handler = new FeatureTriggerHandler();
                                                             
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isBefore){
        handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
    
    
    /*
    if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.newMap);
    }
    else if(Trigger.isDelete && Trigger.isBefore){
        handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }
    else if(Trigger.isDelete && Trigger.isAfter){
        handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    }
    else if(Trigger.isUnDelete){
        handler.OnUndelete(Trigger.new);
    }*/
}