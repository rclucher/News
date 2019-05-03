global with sharing class StandardSalesOrderStateManager implements csmso.SalesOrderAPI.SalesOrderStateManager {
    
    // Define transition status of Sales Order
    static final Map<String, Set<String>> stateTransitions = new Map<String, Set<String>>{
        'Draft' => new Set<String>{'Inactive','Open'},
        'Open' => new Set<String>{'Draft','Inactive','Active'}
    };
    // Define fields or buttons as mandatory, enabled or disabled (ex. set the Finish_Sales_Order button to desabled:'Finish_Sales_Order' => 'D')
    static final Map<String, Map<String, String>> fieldAttributes = new Map<String, Map<String, String>> {
        'Draft' => new Map<String, String> {'Advertiser__c' => 'M','Finish_Sales_Order' => 'D','Status__c' => 'D'}, //When status is set to draft field Advertiser is set as mandatory, button Finish Sales Orderis disabled, Sales Order Status as disabled
        'Open' => new Map<String, String> {'Advertiser__c' => 'M','Status__c' => 'D'} //When status is set to draft field Advertiser is set as disabled and button Finish Sales Orderis enabled, Sales Order Status as disabled
    };
        public void validateChange(csmso__Sales_Order__c so) { //public method validateChange must be defined
            csmso__Sales_Order__c previousSo = [SELECT csmso__Status__c FROM csmso__Sales_Order__c WHERE Id = :so.Id];
            if (previousSo.csmso__Status__c == so.csmso__Status__c) {
                return;
            }
        }
    
    public Map<String, String> getFieldAttributesForSalesOrder(csmso__Sales_Order__c so) { //public method getFieldAttributesForSalesOrder must be defined
        Map<String, String> attribs = fieldAttributes.get(so.csmso__Status__c);
        if (so.csmso__Advertiser__c == null) {
            attribs.put('AddLineItemButton', 'D');
        }
        return attribs;
        // Define different access to Sales Order fields for different profiles
        /*
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String MyProfileName = PROFILE[0].Name;
        if (MyProfileName == 'System Administrator' ){
            attribs.put('Status__c', 'E');
        }*/ 
    }
    public class StateException extends Exception { }
}