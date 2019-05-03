public with sharing class AccountBookingCustomer_ControllerX {

    public Account ac {get; set;}
    public String nameSearch {get; set;}
    public String phoneSearch {get; set;}
    public Boolean privatePartyFlg {get; set;}
    public transient List<Account> searchResults {get; private set;}
    private map<String, Id> accountRecordTypeIdByDeveloperName;


    public AccountBookingCustomer_ControllerX(ApexPages.StandardController controller) {

        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType='Account' AND Name = 'Business Account' LIMIT 1];

        this.ac = new Account(RecordType = rt); 
        this.searchResults = new List<Account>();

        accountRecordTypeIdByDeveloperName = new map<String, Id>();
        for(RecordType art : [Select id, developerName from RecordType where sObjectType = 'Account'])
        {
            accountRecordTypeIdByDeveloperName.put(art.developerName, art.id);
        }

    }

    public PageReference save() {
        insert this.ac;
        return null;
    }

    public PageReference setPersonAccount() {
    
        if (this.privatePartyFlg && accountRecordTypeIdByDeveloperName.containsKey('Private_Party')) {
            this.ac.RecordTypeId = accountRecordTypeIdByDeveloperName.get('Private_Party');
        } else {
            this.ac.RecordTypeId = accountRecordTypeIdByDeveloperName.get('Business_Account_Type');      
        }
        return null;
    }
    
    public PageReference doSearch() {
    
        String nsearchText = this.nameSearch;        
        String searchText = this.phoneSearch;
        this.searchResults = null;
        
        if (this.nameSearch != null && this.nameSearch.length() > 2 ) {
            String searchquery='FIND {' + String.escapeSingleQuotes(this.nameSearch) + 
                               '*} IN NAME FIELDS RETURNING Account(Name, Phone, BillingState)';
                            
//            String searchquery='FIND {' + String.escapeSingleQuotes(this.phoneSearch) + 
//                               '*} IN PHONE FIELDS RETURNING Account(Name, Phone, BillingState)';

            searchquery += ' LIMIT 20';
            List<List<Account>>searchList=search.query(searchquery);
            
            if (searchList.size() > 0) this.searchResults = searchList[0];
        }
        
        return null;
    }
}