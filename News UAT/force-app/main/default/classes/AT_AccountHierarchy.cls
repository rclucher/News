public class AT_AccountHierarchy {
    public class Record {
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String href {get; set;}
        
        @AuraEnabled
        public String ownerID {get; set;}
        @AuraEnabled
        public String ownerName {get; set;}
        @AuraEnabled
        public String ownerHREF {get; set;}
        
        @AuraEnabled
        public Boolean expanded {get; private set;}
        
        @AuraEnabled
        public List<String> expandedRows {get; set;}
        
        @AuraEnabled
        public List<Record> items {get; set;}
        
        @AuraEnabled
        public Decimal spend {get; set;}
        
        @AuraEnabled
        public String relationship {get; set;}
        
        public Record(String name) {
            this.name = name;
            this.label = name;
            
            this.href = '#';
            
            this.items = new List<Record>();
            
            this.expandedRows = new List<String>();
            
            this.expanded = true;
        }
        
        public Record(String id, String name) {
            this.name = id;
            this.label = name;
            
            this.href = '/lightning/r/Account/' + id + '/view';
            
            this.items = new List<Record>();
            
            this.expandedRows = new List<String>();
            
            this.expanded = true;
        }
        
        public Record(String id, String name, String ownerID, String ownerName) {
            this.name = id;
            this.label = name;
            
            this.ownerID = ownerID;
            this.ownerName = ownerName;
            
            this.href = '/lightning/r/Account/' + id + '/view';
            
            this.ownerHREF = '/lightning/r/User/' + ownerID + '/view';
            
            this.items = new List<Record>();
            
            this.expandedRows = new List<String>();
            
            this.expanded = true;
        }
    }
    
    public class Hierarchy {
        @AuraEnabled
        public String type {get; set;}
        
        @AuraEnabled
        public String consortiumID {get; set;}
        @AuraEnabled
        public String consortiumName {get; set;}
        
        @AuraEnabled
        public List<Record> records {get; set;}
        
        public Hierarchy() {
            this.records = new List<Record>();
        }
    }
    
	@AuraEnabled
    public static Hierarchy getAccountHierarchy(String recordID) {
        Hierarchy hierarchy = new Hierarchy();
        
        Account acc = [SELECT RecordType.DeveloperName, Account_Type__c, Consortium__c FROM Account WHERE Id = :recordID];
        
        if (acc.Account_Type__c == 'Consortium') {
            hierarchy.type = 'consortium';
        } else if (acc.RecordType.DeveloperName == 'Agency_Account_Type') {
            hierarchy.type = 'agency';
        } else {
            hierarchy.type = 'client';
        }
        
        if (hierarchy.type == 'consortium') {
            List<Record> agencies = new List<Record>();
            
            Map<String, Map<String, List<Record>>> agencyRelationshipClients = new Map<String, Map<String, List<Record>>>();
            
            for (Account ag: [SELECT Id, Name, OwnerId, Owner.Name, Current_FY__c FROM Account WHERE Consortium__c = :recordID ORDER BY Name ASC]) {
                Record agency = new Record(ag.Id, ag.Name, ag.OwnerId, ag.Owner.Name);
                    
                agency.spend = (ag.Current_FY__c != null) ? ag.Current_FY__c : 0;
                
                agencies.add(agency);
            }
            
            for (Account_Services_Rel__c rel: [SELECT Services__c, Source_Account__c, Source_Account__r.Name, Source_Account__r.OwnerId, Source_Account__r.Owner.Name, Source_Account__r.Current_FY__c, Target_Account__c, Target_Account__r.Name, Target_Account__r.Current_FY__c, Target_Account__r.OwnerId, Target_Account__r.Owner.Name FROM Account_Services_Rel__c WHERE (Source_Account__r.Consortium__c = :recordID) ORDER BY Source_Account__r.Name ASC, Services__c, Target_Account__r.Name ASC]) {
                Record client = new Record(rel.Target_Account__c, rel.Target_Account__r.Name, rel.Target_Account__r.OwnerId, rel.Target_Account__r.Owner.Name);
                
                client.spend = (rel.Target_Account__r.Current_FY__c != null) ? rel.Target_Account__r.Current_FY__c : 0;
                
                appendToMap(agencyRelationshipClients, String.valueOf(rel.Source_Account__c), rel.Services__c, client);
            }
            
            for (Record a: agencies) {
                Map<String, List<Record>> relationships = agencyRelationshipClients.get(a.name);
                
                //a.spend = 0;
                
                if (relationships != null) {
                    for (String rel: relationships.keySet()) {
                        Record relationship = new Record(rel);
                        
                        relationship.items = relationships.get(rel);
                        
                        //for (Record r: relationship.items) a.spend += r.spend;
                        
                        a.items.add(relationship);
                        
                        /*Commenting this to collapse the output records. Refer to Jira: NR-1587*/
                        //a.expandedRows.add(rel);
                    }
                }
            }
            
            hierarchy.records = agencies;
        } else if (hierarchy.type == 'agency') {
            Account agency = [SELECT Id, Name, Consortium__c, Consortium__r.Name, Owner.Name FROM Account WHERE Id = :recordID];
            
            hierarchy.consortiumID = agency.Consortium__c;
            hierarchy.consortiumName = agency.Consortium__r.Name;
            
            List<Record> agencies = new List<Record>();
            
            Map<String, Map<String, List<Record>>> agencyRelationshipClients = new Map<String, Map<String, List<Record>>>();
            
            for (Account_Services_Rel__c rel: [SELECT Services__c, Source_Account__c, Source_Account__r.Name, Source_Account__r.OwnerId, Source_Account__r.Owner.Name, Source_Account__r.Current_FY__c, Target_Account__c, Target_Account__r.Name, Target_Account__r.Current_FY__c, Target_Account__r.OwnerId, Target_Account__r.Owner.Name FROM Account_Services_Rel__c WHERE (Source_Account__c = :recordID) ORDER BY Services__c ASC, Target_Account__r.Name ASC]) {
                if (agencyRelationshipClients.get(rel.Source_Account__c) == null) {
                    //agencies.add(new Record(rel.Source_Account__c, rel.Source_Account__r.Name, rel.Source_Account__r.OwnerId, rel.Source_Account__r.Owner.Name));
                    
                    Record ag = new Record(rel.Source_Account__c, rel.Source_Account__r.Name, rel.Source_Account__r.OwnerId, rel.Source_Account__r.Owner.Name);
                    
                    ag.spend = (rel.Source_Account__r.Current_FY__c != null) ? rel.Source_Account__r.Current_FY__c : 0;
                        
                    agencies.add(ag);
                }
            
                Record client = new Record(rel.Target_Account__c, rel.Target_Account__r.Name, rel.Target_Account__r.OwnerId, rel.Target_Account__r.Owner.Name);
                
                client.spend = (rel.Target_Account__r.Current_FY__c != null) ? rel.Target_Account__r.Current_FY__c : 0;
                
                appendToMap(agencyRelationshipClients, String.valueOf(rel.Source_Account__c), rel.Services__c, client);            }
            
            for (Record a: agencies) {
                Map<String, List<Record>> relationships = agencyRelationshipClients.get(a.name);
                
                //a.spend = 0;
                
                if (relationships != null) {
                    for (String rel: relationships.keySet()) {
                        Record relationship = new Record(rel);
                        
                        relationship.items = relationships.get(rel);
                        
                        //for (Record r: relationship.items) a.spend += r.spend;
                        
                        a.items.add(relationship);
                        
                        /*Commenting this to collapse the output records. Refer to Jira: NR-1587*/
                        //a.expandedRows.add(rel);
                    }               }            }
            
            hierarchy.records = agencies;
            
            System.debug(hierarchy.records);
            
            /*List<Record> agencies = new List<Record>();
            
            List<Record> clients = new List<Record>();
            
            Decimal totalSpend = 0;
            
            for (Account_Services_Rel__c rel: [SELECT Services__c, Target_Account__c, Target_Account__r.Name, Target_Account__r.Owner.Name, Target_Account__r.Current_FY__c FROM Account_Services_Rel__c WHERE (Source_Account__c = :recordID) ORDER BY Target_Account__r.Name ASC]) {
                clients.add(new Record(rel.Target_Account__c, rel.Target_Account__r.Name + ' (' + rel.Target_Account__r.Owner.Name + ') (Relationship: ' + rel.Services__c + ')'));
                            
                totalSpend += rel.Target_Account__r.Current_FY__c;
            }
            
            Record agencyRecord = new Record(agency.Id, agency.Name + ' (' + agency.Owner.Name + '), Current FY Spend:  $' + totalSpend);
            agencyRecord.items = clients;
                
            agencies.add(agencyRecord);
            
            hierarchy.records = agencies;*/
        } else if (hierarchy.type == 'client') {
            List<Record> consortiums = new List<Record>();
            
            Map<String, List<Record>> consortiumAgencyMap = new Map<String, List<Record>>();
            
            for (Account_Services_Rel__c rel: [SELECT Source_Account__c, Source_Account__r.Name, Source_Account__r.Owner.Name, Source_Account__r.Consortium__c, Source_Account__r.Consortium__r.Name, Services__c, Source_Account__r.Current_FY__c FROM Account_Services_Rel__c WHERE (Target_Account__c = :recordID) ORDER BY Source_Account__r.Consortium__r.Name ASC, Source_Account__r.Name ASC]) {
                if (consortiumAgencyMap.get(rel.Source_Account__r.Consortium__c) == null) {
                    consortiums.add(new Record(rel.Source_Account__r.Consortium__c, rel.Source_Account__r.Consortium__r.Name));
                }
                
                Record agency = new Record(rel.Source_Account__c, rel.Source_Account__r.Name, rel.Source_Account__r.OwnerId, rel.Source_Account__r.Owner.Name);
                
                agency.relationship = rel.Services__c;
                agency.spend = (rel.Source_Account__r.Current_FY__c != null) ? rel.Source_Account__r.Current_FY__c : 0;
                
                appendToMap(consortiumAgencyMap, rel.Source_Account__r.Consortium__c, agency);
            }
            
            for (Record c: consortiums) {
                List<Record> agencies = consortiumAgencyMap.get(c.name);
                
                if (agencies != null) c.items = agencies;
            }
            
            hierarchy.records = consortiums;
        }
        
        return hierarchy;
    } 
    
    private static void appendToMap(Map<String, List<Record>> listMap, String key, Record value) {
        List<Record> existing = listMap.get(key);
        
        if (existing == null) {
            existing = new List<Record>();
            
            listMap.put(key, existing);
        }
        
        existing.add(value);
    }
    
    private static void appendToMap(Map<String, Map<String, List<Record>>> outerMap, String outerKey, String innerKey, Record value) {
        Map<String, List<Record>> innerMap = outerMap.get(outerKey);
        
        if (innerMap == null) innerMap = new Map<String, List<Record>>();
        
        List<Record> records = innerMap.get(innerKey);
        
        if (records == null) records = new List<Record>();
        
        records.add(value);
        
        innerMap.put(innerKey, records);
        
        outerMap.put(outerKey, innerMap);
    }
}