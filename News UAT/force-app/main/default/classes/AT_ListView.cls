public class AT_ListView extends VisualEditor.DynamicPickList {
    public class Column {
        @AuraEnabled
        public String label {get; private set;}
        
        @AuraEnabled
        public String fieldName {get; private set;}
        
        @AuraEnabled
        public String type {get; private set;}
        
        @AuraEnabled
        public TypeAttributes typeAttributes {get; private set;}
        
        public Column(String label, String fieldName, String type) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
            
            this.typeAttributes = null;
        }
        
        public Column(String label, String fieldName, String type, TypeAttributes typeAttributes) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
            
            this.typeAttributes = typeAttributes;
        }
    }
    
    public class TypeAttributes {
        @AuraEnabled
        public FieldAttributes label {get; private set;}
        
        public TypeAttributes(FieldAttributes label) {
            this.label = label;
        }
    }
    
    public class Actions {
        @AuraEnabled
        public String label {get; private set;}
        
        @AuraEnabled
        public String name {get; private set;}
        
        public Actions(String label, String name) {
            this.label = label;
            this.name  = name;
        }
    }
    
    public class FieldAttributes {
        @AuraEnabled
        public String fieldName {get; private set;}
        
        public FieldAttributes(String fieldName) {
            this.fieldName = fieldName;
        }
    }
    
    public class Results {
		@AuraEnabled
        public Integer total {get; private set;}
        
        @AuraEnabled
        public Integer pages {get; private set;}
        
        @AuraEnabled
        public List<Column> columns {get; private set;}
        
        @AuraEnabled
        public List<SObject> records {get; private set;}
        
        public Results(Integer total, Integer pages, List<Column> columns, List<SObject> records) {
            this.total   = total;
            this.pages   = pages;
            this.records = records;
            this.columns = columns;
        }
    }
    
    private static String mapFieldType(Schema.DisplayType type) {
        if (type == Schema.DisplayType.COMBOBOX) return 'text';
        if (type == Schema.DisplayType.INTEGER) return 'number';
        if (type == Schema.DisplayType.DOUBLE) return 'number';
        if (type == Schema.DisplayType.CURRENCY) return 'currency';
        if (type == Schema.DisplayType.PICKLIST) return 'text';
        if (type == Schema.DisplayType.MULTIPICKLIST) return 'text';
        if (type == Schema.DisplayType.DATE) return 'date';
        if (type == Schema.DisplayType.DATETIME) return 'date';
        if (type == Schema.DisplayType.EMAIL) return 'email';
        
        return 'text';
    }
    
    public class ObjectInfo {
        @AuraEnabled
        public String name {get; set;}
        
        @AuraEnabled
        public String title {get; set;}
        
        @AuraEnabled
        public String icon {get; set;}
        
        @AuraEnabled
        public Boolean compactOnly {get; set;}
        
        @AuraEnabled
        public Boolean canCreate {get; set;}
    }
    
    @AuraEnabled
    public static ObjectInfo getObjectInfo(String configName) {
        ObjectInfo info = new ObjectInfo();
        
        AT_ListView_Config__mdt config = [SELECT Label, Icon__c, Object__c, Compact_FieldSet__c, Full_FieldSet__c, Query_Filter__c, Order_By__c, Order_Direction__c, Record_Types__c, Compact_View_Only__c FROM AT_ListView_Config__mdt WHERE DeveloperName = :configName];
        
        info.name = config.Object__c;
        info.title = config.Label;
        info.icon = config.Icon__c;
        info.compactOnly = config.Compact_View_Only__c;
        info.canCreate = Schema.getGlobalDescribe().get(config.Object__c).getDescribe().isCreateable();
        
        return info;
    }
    
    @AuraEnabled
    public static List<String> getConfigs() {
        List<String> configs = new List<String>();
        
        for (AT_ListView_Config__mdt config: [SELECT DeveloperName FROM AT_ListView_Config__mdt]) {
            configs.add(config.DeveloperName);
        }
        
        return configs;
    }
    
    @AuraEnabled
    public static Results getRecords(String configName, String viewMode, Integer maxCount, Integer pageSize, Integer pageNumber) {
        System.debug('Config name: ' + configName);
        
        AT_ListView_Config__mdt config = [SELECT Ownership__c, Object__c, Compact_FieldSet__c, Full_FieldSet__c, Query_Filter__c, Order_By__c, Order_Direction__c, Record_Types__c, Compact_View_Only__c FROM AT_ListView_Config__mdt WHERE DeveloperName = :configName];
        
        Set<Id> recordTypeIDs = new Set<Id>();
        Set<Id> roleIDs = new Set<Id>();
        
        if (String.isNotBlank(config.Record_Types__c)) {
            List<String> rtNames = config.Record_Types__c.split(',');
            
            for (RecordType rt: [SELECT Id FROM RecordType WHERE SObjectType = :config.Object__c AND DeveloperName IN :rtNames]) {
                recordTypeIDs.add(rt.Id);
            }
        }
        
        Map<String, String> fieldTypes = new Map<String, String>();
        
        String objectFilter = config.Object__c + '.%';
        Integer nameLength = config.Object__c.length() + 1;
        
        for (AT_Object_Field_Types__mdt ft: [SELECT Label, Type__c FROM AT_Object_Field_Types__mdt WHERE Label LIKE :objectFilter]) {
            fieldTypes.put(ft.Label.substring(nameLength), ft.Type__c);
        }
        
        System.debug('Field type map: ' + fieldTypes);
        
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(config.Object__c).getDescribe();
        
        Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();
        
        List<String> fields = new List<String>();
        
        List<Column> columns = new List<Column>();
        
        String fieldSetName = ((String.valueOf(viewMode) == 'full' && !String.isBlank(config.Full_FieldSet__c)) ? config.Full_FieldSet__c : config.Compact_FieldSet__c);
        
        for (Schema.FieldSetMember field: describe.FieldSets.getMap().get(fieldSetName).getFields()) {
            if (field.getFieldPath() != 'Id') {
                System.debug(field.getFieldPath());
                System.debug(field.getType());
                
                if (fieldMap.get(field.getFieldPath()).getDescribe().isAccessible()) {
                    fields.add(field.getFieldPath());
                    
                    if (field.getType() == Schema.DisplayType.REFERENCE) {
                        String refField = field.getFieldPath();
                        
                        String nameField;
                        
                        if (refField.endsWith('__c')) {
                            nameField = refField.left(refField.length() - 3) + '__r.Name';
                        } else if (refField.endsWith('Id')) {
                            nameField = refField.left(refField.length() - 2) + '.Name';
                        } else {
                            nameField = refField + '.Name';
                        }
                        
                        fields.add(nameField);
                        
                        System.debug(refField + ' -> ' + nameField);
                        
                        columns.add(new Column(field.getLabel(), refField, 'url', new TypeAttributes(new FieldAttributes(nameField))));
                    } else if (field.getFieldPath() == 'Name') {
                        columns.add(new Column(field.getLabel(), 'Id', 'url', new TypeAttributes(new FieldAttributes('Name'))));
                    } else if (field.getFieldPath() == 'FirstName') {
                        columns.add(new Column(field.getLabel(), 'Id', 'url', new TypeAttributes(new FieldAttributes('FirstName'))));
                    } else if (field.getFieldPath() == 'LastName') {
                        columns.add(new Column(field.getLabel(), 'Id', 'url', new TypeAttributes(new FieldAttributes('LastName'))));
                    } else if (field.getFieldPath() == 'CaseNumber') {
                        columns.add(new Column(field.getLabel(), 'Id', 'url', new TypeAttributes(new FieldAttributes('CaseNumber'))));
                    } else {
                        String fieldType = fieldTypes.get(field.getFieldPath());
                        
                        if (fieldType == null) fieldType = mapFieldType(field.getType());
                        
                    	columns.add(new Column(field.getLabel(), field.getFieldPath(), fieldType));
                    }
                }
            }
        }
        
        System.debug('Fields: ' + fields);
        System.debug('Columns: ' + columns);
        
		List<String> filters = new List<String>();
        
        if (!recordTypeIDs.isEmpty()) filters.add('RecordTypeId IN :recordTypeIDs');
        if (String.isNotBlank(config.Query_Filter__c)) filters.add(config.Query_Filter__c);
        
		String query = 'SELECT Id,' + String.join(fields, ',') + ' FROM ' + config.Object__c;
            
        if (config.Ownership__c == 'Directly Owned') {
            filters.add('OwnerId = \'' + UserInfo.getUserId() + '\'');
        } else if (config.Ownership__c == 'Hierarchy') {
            roleIDs = AT_AccessUtil.getCurrentUserRoleAndSubordinates();
            
            filters.add('(OwnerId = \'' + UserInfo.getUserId() + '\' OR Owner.UserRoleId IN :roleIDs)');
        }
        
        if (!filters.isEmpty()) query += ' WHERE ' + String.join(filters, ' AND ');
        
        if (!String.isBlank(config.Order_By__c)) query += (' ORDER BY ' + config.Order_By__c + ' ' + (config.Order_Direction__c == 'Descending' ? 'DESC' : 'ASC'));
        
        query += ' LIMIT ' + ((maxCount == null) ? 50000 : maxCount);
        
        System.debug('Query: ' + query);
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        
        Integer pageCount = Integer.valueOf(pageSize);
        
        setCon.setPageSize(pageCount);
        
        setCon.setPageNumber(Integer.valueOf(pageNumber));
        
        Decimal totalCount = Decimal.valueOf(setCon.getResultSize());
        
        System.debug('Return: ' + setCon.getRecords());
        
        return new Results((Integer)totalCount, (Integer)Math.ceil(totalCount / pageCount) , columns, setCon.getRecords());
    }
    
    public class Summary {
        @AuraEnabled
        public String name {get; set;}
        
        @AuraEnabled
        public String title {get; set;}
        
        @AuraEnabled
        public String icon {get; set;}
        
        @AuraEnabled
        public Integer count {get; set;}
        
        @AuraEnabled
        Boolean compactOnly {get; set;}
    }
    
    @AuraEnabled
    public static Summary getSummary(String configName) {
        AT_ListView_Config__mdt config = [SELECT DeveloperName, Label, Icon__c, Ownership__c, Object__c, Compact_FieldSet__c, Full_FieldSet__c, Query_Filter__c, Order_By__c, Order_Direction__c, Record_Types__c, Compact_View_Only__c FROM AT_ListView_Config__mdt WHERE DeveloperName = :configName];
        
        Set<Id> recordTypeIDs = new Set<Id>();
        Set<Id> roleIDs = new Set<Id>();
        
        if (String.isNotBlank(config.Record_Types__c)) {
            List<String> rtNames = config.Record_Types__c.split(',');
            
            for (RecordType rt: [SELECT Id FROM RecordType WHERE SObjectType = :config.Object__c AND DeveloperName IN :rtNames]) {
                recordTypeIDs.add(rt.Id);
            }
        }
        
        Map<String, String> fieldTypes = new Map<String, String>();
        
        String objectFilter = config.Object__c + '.%';
        Integer nameLength = config.Object__c.length() + 1;
        
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(config.Object__c).getDescribe();
                
		String query = 'SELECT COUNT(Id) total FROM ' + config.Object__c;
            
        List<String> filters = new List<String>();
        
        if (!recordTypeIDs.isEmpty()) filters.add('RecordTypeId IN :recordTypeIDs');
        if (String.isNotBlank(config.Query_Filter__c)) filters.add(config.Query_Filter__c);
        
        if (config.Ownership__c == 'Directly Owned') {
            filters.add('OwnerId = \'' + UserInfo.getUserId() + '\'');
        } else if (config.Ownership__c == 'Hierarchy') {
            roleIDs = AT_AccessUtil.getCurrentUserRoleAndSubordinates();
            
            filters.add('(OwnerId = \'' + UserInfo.getUserId() + '\' OR Owner.UserRoleId IN :roleIDs)');
        }
        
        if (!filters.isEmpty()) query += ' WHERE ' + String.join(filters, ' AND ');
        
        System.debug('Query: ' + query);
        
        List<AggregateResult> results = Database.query(query);
        
        Summary summary = new Summary();
        summary.name = config.DeveloperName;
        summary.title = config.Label;
        summary.icon = config.Icon__c;
        summary.compactOnly = config.Compact_View_Only__c;
        
        summary.count = (results.isEmpty() ? 0 : (Integer)results[0].get('total'));
        
        if (config.Compact_View_Only__c && (summary.count > 10)) summary.count = 10;
        
        return summary;
    }
    
    public override VisualEditor.DataRow getDefaultValue() {
        List<AT_ListView_Config__mdt> configs = [SELECT Label, DeveloperName FROM AT_ListView_Config__mdt ORDER BY Label LIMIT 1];
        
        if (!configs.isEmpty()) return new VisualEditor.DataRow(configs[0].Label, configs[0].DeveloperName);
        
        return null;
    }
    
    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows configs = new VisualEditor.DynamicPickListRows();
        
        for (AT_ListView_Config__mdt config: [SELECT Label, DeveloperName FROM AT_ListView_Config__mdt ORDER BY Label]) {
            configs.addRow(new VisualEditor.DataRow(config.Label, config.DeveloperName));
        }
        
        return configs;
    }
}