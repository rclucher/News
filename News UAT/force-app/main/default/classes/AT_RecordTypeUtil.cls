public with sharing class AT_RecordTypeUtil {
    
    public class RecordTypeInfo {
    	@AuraEnabled
        public Id      id          {get; private set;}
        @AuraEnabled
        public String  name        {get; private set;}
        @AuraEnabled
        public String  description {get; private set;}
        @AuraEnabled
        public Boolean isDefault   {get; private set;}
        
        public RecordTypeInfo(Id id, String name, String description, Boolean isDefault) {
            this.Id          = id;
            this.name        = name;
            this.description = description;
            this.isDefault   = isDefault;
        }
    }
    
    @AuraEnabled
    public static List<RecordTypeInfo> getRecordTypes(String objectName) {
        List<RecordType> types = [SELECT Id, Name, Description FROM RecordType WHERE (SObjectType = :objectName) AND (IsActive = true)];

        Map<Id, Schema.RecordTypeInfo> rtMap = Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById();
            
        List<RecordTypeInfo> rtInfo = new List<RecordTypeInfo>();
        
        for (RecordType rt : types) {
            Schema.RecordTypeInfo rti = rtMap.get(rt.Id);
            
            if ((rti != null) && rti.isAvailable()) {
                rtInfo.add(new RecordTypeInfo(rt.Id, rt.Name, rt.Description, rti.isDefaultRecordTypeMapping()));
            }
        }
        
        return rtInfo;
    }
}