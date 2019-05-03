/**
* @company      Bluewolf
* @author       Noel Lim (noel.lim@bluewolf.com)
* @date         21/11/2014
* @description  Trigger Handler for Feature
*/
public class FeatureTriggerHandler {

    Map<String, String> productState;
    
    public FeatureTriggerHandler(){
        Map<String, Feature_Product_State__c> fpsCustomSetting = Feature_Product_State__c.getAll(); 
        productState = new Map<String, String>();
        
        for(String id : fpsCustomSetting.keySet()){
            productState.put(fpsCustomSetting.get(id).Product__c,fpsCustomSetting.get(id).State__c);
        }
    }

    public void OnBeforeUpdate(Feature__c[] oldFeatures, Feature__c[] newFeatures,
                               Map<Id, Feature__c> oldFeaturesMap, Map<Id, Feature__c> newFeaturesMap){
                    
        for(Id fId : newFeaturesMap.keySet()){
            Feature__c f = newFeaturesMap.get(fId);
            Feature__c oldF = oldFeaturesMap.get(fId);
            if(String.isEmpty(f.State__c) && productState.containsKey(f.Product__c)){
                f.State__c = productState.get(f.Product__c);
            }
            
        }
    }
    
    public void OnBeforeInsert(Feature__c[] newFeatures){
        
        for(Feature__c f : newFeatures){
            if(productState.containsKey(f.Product__c)){
                f.State__c = productState.get(f.Product__c);
            }
        }
    }

    
    /** UNUSED
    public void OnAfterInsert(Object[] newObjects){
        // EXECUTE BEFORE INSERT LOGIC
    }

    public void OnAfterUpdate(Object[] oldObjects, Object[] updatedObjects, MapObjectMap){
        // BEFORE UPDATE LOGIC
    }

    public void OnBeforeDelete(Object[] ObjectsToDelete, MapObjectMap){
        // BEFORE DELETE LOGIC
    }

    public void OnAfterDelete(Object[] deletedObjects, MapObjectMap){
        // AFTER DELETE LOGIC
    }

    public void OnUndelete(Object[] restoredObjects){
        // AFTER UNDELETE LOGIC
    }

    */
}