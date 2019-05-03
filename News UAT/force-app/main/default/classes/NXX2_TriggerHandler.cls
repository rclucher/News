/**
* @author       Kamal Sharma
* @date         2019-01-02
* @className	NXX2_TriggerHandler
* @description  This interface is the part of framwork used for trigger. 
*				All trigger handler classes having impact as a part of My Account requirement will implimenet this.
*/
public interface NXX2_TriggerHandler 
{
    void BeforeInsert(List<SObject> newItems);
 
    void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
 
    void BeforeDelete(Map<Id, SObject> oldItems);
 
    void AfterInsert(Map<Id, SObject> newItems);
 
    void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
 
    void AfterDelete(Map<Id, SObject> oldItems);
 
    void AfterUndelete(Map<Id, SObject> oldItems);
 
    Boolean IsDisabled();
}