public with sharing class AT_CreateAccount {
    //private static final String datasanKey = 'bmV3c3VzZXI6WFFzbjhsV0tvMGZLYW9Qd1RNRzU5TmFzVUZ3QWZhbDE=';
    
    //private static final Set<String> nextgenProfiles = new Set<String>{'IMA Sales','IMA Sales Digital','IMA Sales Support','KAC Sales','KAC Sales Support','SME Field Sales Account Manager','SME Sales','SME Sales Digital','SME Sales Support','The Aus Sales','The Aus Sales Digital','The Aus Sales Support','Real Estate Sales','~System Administrator','System Administrator'};
    
    public Account acc {get; set;}
    
    public String returnURL {get; private set;}
    
    public String recordTypeID {get; set;}
    
    public String defaultID {get; private set;}
    public String defaultName {get; private set;}
    public List<SelectOption> recordTypes {get; private set;}
    
    public String accountName {get; set;}
    public String companyABN {get; set;}
    public String exemptReason {get; set;}
    
    public String registeredName {get; set;}
    public String abnStatus {get; set;}
    
    public String country {get; set;}
    public List<SelectOption> countries {get; private set;}
    
    public List<SelectOption> exemptReasons {get; private set;}
    
    public String addressSearch {get; set;}
    public List<SelectOption> addresses {get; private set;}
    public Integer addressCount {get; private set;}
    public String selectedAddress {get; set;}
    
    public List<DataSanAddress> addressList {get; private set;}
    
    public Boolean validated {get; set;}
    
    public AT_CreateAccount(ApexPages.StandardController controller) {
        recordTypes = new List<SelectOption>();
        
        for (AT_RecordTypeUtil.RecordTypeInfo rt: getRecordtypes()) {
            if (rt.isDefault) {
                recordTypeID = rt.id;
                defaultID = rt.id;
                defaultName = rt.name + ' (' + rt.description + ')';
            } else {
                recordTypes.add(new SelectOption(rt.id, rt.name + ' (' + rt.description + ')'));
            }
        }
        
        exemptReasons = new List<SelectOption>();
        exemptReasons.add(new SelectOption('RQ', 'No'));
        exemptReasons.add(new SelectOption('PP', 'Yes - Private Party (less than $75k turnover)'));
        exemptReasons.add(new SelectOption('NFP', 'Yes - Not for Profit'));
        exemptReasons.add(new SelectOption('OS', 'Yes - Overseas Client'));
        
        exemptReason = 'RQ';
        
        countries = new List<SelectOption>();
        countries.add(new SelectOption('AUSTRALIA', 'Australia'));
        countries.add(new SelectOption('NEW ZEALAND', 'New Zealand'));
        countries.add(new SelectOption('', 'Other'));
        
        country = 'AUSTRALIA';
        
        addressCount = 0;
        
        validated = false;
        
        acc = new Account();
        
        returnURL = ApexPages.currentPage().getParameters().get('retURL');
    }
    
    /*
     * Check if the user should be shown the default New screen or the custom one
     */
    public PageReference checkAccess() {
        System.debug('Test user: ' + UserInfo.getUserId() + ', Name: ' + UserInfo.getUserName() + ', Profile ID: ' + UserInfo.getProfileId());
        
        String userProfileName = [Select Name from Profile where Id = :UserInfo.getProfileId()].Name;
        
        System.debug('Test user profile name: ' + userProfileName);
        
        // See if the current user's profile name is in the list of NextGen profiles
        List<NextGen_User_Profile__mdt> nextgenProfiles = [SELECT Id FROM NextGen_User_Profile__mdt WHERE Label = :userProfileName];
        
        // If the query returned no results then it means that this is not a NextGen user,
        // so direct them to default screen.
        if (nextgenProfiles.isEmpty()) {
            // Find the return URL given to the controller, save it aside and pass it onto the record type selection page
            String returnURL = ApexPages.currentPage().getParameters().get('retURL');
            
            // Show the standard record type selection screen
            PageReference defaultNew = new PageReference('/setup/ui/recordtypeselect.jsp');
        
            Map<String, String> params = defaultNew.getParameters();
        
            if (String.isNotBlank(returnURL)) params.put('retURL', returnURL);
            
            // Show the Account record types
            params.put('ent', 'Account');
            
            // Direct the user to the standard New Account screen after selecting the record type
            params.put('save_new_url', '/001/e?nooverride=1');
            
            defaultNew.setRedirect(true);
            
            return defaultNew;
        }
        
        // If execution has reached here then it means that their profile matched one in the NextGen list,
        // so do nothing else and continue to the custom screen.
        return null;
    }

    public PageReference cancel() {
        PageReference ref = new PageReference(String.isBlank(returnURL) ? '/001' : returnURL);
        
        ref.setRedirect(true);
        
        return ref;
    }
    
    public PageReference validate() {
        Integer errors = 0;
        
        if (String.isBlank(acc.Name)) {
            acc.Name.addError('Name must be entered');
            errors++;
        }

        if ((exemptReason == 'RQ') && String.isBlank(companyABN)) {
            if (String.isBlank(acc.AccountNumber)) {
                acc.AccountNumber.addError('Enter a valid ABN');
            	errors++;
            } else {
                checkABN();
                
                if (String.isBlank(companyABN)) {
                    acc.AccountNumber.addError('Enter a valid ABN');
            		errors++;
                }
            }
        }
        
        if (errors > 0) return null;
        
        System.debug('Rec: ' + recordTypeID);
        
        Map<String, String> fields = getFieldIDs(recordTypeID);
        
        PageReference p = new PageReference('/' + Account.SObjectType.getDescribe().getKeyPrefix() + '/e');
        
        Map<String, String> m = p.getParameters();
        
        m.put('nooverride', '1');
        m.put('ent', 'Account');
        m.put('RecordType', recordTypeID);

        /*
		'RecordTypeId': component.get("v.recordTypeId"),
        'Name': component.get("v.accountName"),
        'ABN_Exempt__c': exempt,
        'ABN_Exempt_Reason__c': exemptReason,
        'AccountNumber': abn,
        'Registered_Name__c': component.get("v.companyName"),
        'ABN_Status__c': component.get("v.abnStatus"),
        'ABN_Validation__c': timestamp,
        'BillingStreet': component.get("v.street"),
        'BillingCity': component.get("v.city"),
        'BillingPostalCode': component.get("v.postcode"),
        'BillingState': component.get("v.state"),
        'BillingCountry': component.get("v.country"),
        'DPID_Primary_Address__c': component.get("v.dpid"),
		'datasan__Billing_Address_DPID__c': component.get("v.dpid")
         */
        System.debug('1');
        m.put(fields.get('Account Name'), acc.Name);
        System.debug('2');
        if (exemptReason != 'RQ') {
            System.debug('3');
        	if (fields.get('ABN Exempt') != null) m.put(fields.get('ABN Exempt'), '1');
            System.debug('4');
            String reason;
            
            if (exemptReason == 'PP') reason = 'Private Party (less than $75k turnover)';
            if (exemptReason == 'NFP') reason = 'Not for Profit';
            if (exemptReason == 'OS') reason = 'Overseas Client';
            System.debug('5');
        	if (fields.get('ABN Exempt Reason') != null) m.put(fields.get('ABN Exempt Reason'), reason);
            System.debug('6');
        } else {
            m.put(fields.get('ABN'), companyABN);System.debug('7');
            m.put(fields.get('Registered Name'), registeredName);System.debug('8');
        	m.put(fields.get('ABN Status'), abnStatus);System.debug('9');
        	m.put(fields.get('ABN Validation'), System.now().format('dd/MM/yyyy'));System.debug('10');
        }
        
        if (!String.isBlank(selectedAddress)) {
            for (DataSanAddress addr: addressList) {
                if (addr.eid == selectedAddress) {
                    String addressStreet = (String.isBlank(addr.subdwelling) ? '' : addr.subdwelling + ' ') + addr.streetNumber + addr.street;
                    
                    m.put(fields.get('Primary Street'), addressStreet);System.debug('11');
                    m.put(fields.get('Primary City'), addr.locality);System.debug('12');
                    m.put(fields.get('Primary Postcode'), addr.postcode);System.debug('13');
                    m.put(fields.get('Primary State'), addr.state);System.debug('14');
                    m.put(fields.get('Primary Country'), country);System.debug('15');
                    m.put(fields.get('DPID - Primary Address'), addr.attributes.DPID);System.debug('16');
                }
            }
        }
        
        return p;
    }
    
    public class DataSanResponse {
        public String status;
        public String message;
        public List<DataSanAddress> payload;
    }
    
    public class DataSanAddress {
        public String eid;
        public String fullAddress;
        
        public String subdwelling;
        public String streetNumber;
        public String street;
        public String locality;
        public String postcode;
        public String state;
        public String country;
        public AddressAttributes attributes;
    }
    
    public class AddressAttributes {
        public String DPID;
    }
    
    public PageReference searchAddress() {
        addresses = new List<SelectOption>();
        
        addressList = new List<DataSanAddress>();

		System.debug('Searching: ' + addressSearch);
        
        addressCount = 0;
        
        if (!String.isBlank(addressSearch) && (addressSearch.length() > 5)) {
            String toSearch = addressSearch.replaceAll('[^\\w\\d\\s\\/\\.\\(\\),-]+', '');
            
            String results = lookupAddress(toSearch, 'AUPAF');
            
            DataSanResponse response = (DataSanResponse)JSON.deserialize(results, DataSanResponse.class);
            
            System.debug(response);
            
            if ((response.status != 'ERROR') && (response.payload != null)) {
                for (DataSanAddress addr: response.payload) {
                    addresses.add(new SelectOption(addr.eid, addr.fullAddress));
                    
                    addressList.add(addr);
                    
                    addressCount++;
                    
                    if (addressCount == 100) break;
                }
            }
        }
        
        return null;
    }
    
    public PageReference checkABN() {
        if (!String.isBlank(acc.AccountNumber)) {
            acc.AccountNumber = acc.AccountNumber.replace(' ', '').replace('\t', '');
            
            AccountInfo info = lookupABN(acc.AccountNumber);
            
            if (info != null) {
                companyABN = info.ABN;
                registeredName = info.name;
                abnStatus = info.status;
            }
        } else {
            
        }
        
        return null;
    }
    
    public Map<String, String> getFieldIDs(String recordTypeID) {
        //Map<String, String> fieldMap = new Map<String, String>();
        
        //for (SObjectField f : Account.SObjectType.getDescribe().fields.getMap().values()) {
            //fieldMap.put(f.getDescribe().getLabel(), f.getDescribe().getName());
            
            //System.debug(f.getDescribe().getLabel() + ' :: ' + f.getDescribe().getName());
        //}
        
        // Obtain the magic ids
        PageReference p = new PageReference('/' + Account.SObjectType.getDescribe().getKeyPrefix() + '/e?nooverride=1&ent=Account&RecordType=' + recordTypeID);
        String html = p.getContent().toString();
        Map<String, String> labelToId = new Map<String, String>();
        Matcher m = Pattern.compile('<label for="(.*?)">(<span class="requiredMark">\\*</span>)?(.*?)</label>').matcher(html);
        while (m.find()) {
            String label = m.group(3).replace('<span class="assistiveText">*</span>', '');
            String id = m.group(1);
            
            //String apiName = fieldMap.get(label);
            
            //System.debug(label + ' -> ' + apiName + ' -> ' + id);
            labelToId.put(label, id);
        }
        
        return labelToId;
    }
    
    public class AccountInfo {
        @AuraEnabled
        public String abn {get; private set;}
        @AuraEnabled
        public String name {get; private set;}
        @AuraEnabled
        public Boolean isActive {get; private set;}
        @AuraEnabled
        public String status {get; private set;}
        
        @AuraEnabled
        public Boolean isInvalid {get; private set;}
        
        public AccountInfo(String abn, String name, Boolean isActive, String status, Boolean isInvalid) {
            this.isInvalid = isInvalid;
            this.status = status;
            this.name = name;
            
            this.abn = abn;
            this.isActive = isActive;
        }
        
        public AccountInfo() {
            this.isInvalid = true;
            this.status = 'Invalid';
            this.name = '';
            
            this.abn = '';
            this.isActive = false;
        }
    }
    
    public class ExistingAccount {
        @AuraEnabled
        public Id Id {get; set;}
        
        @AuraEnabled
        public String Link {get; set;}
        
        @AuraEnabled
        public String Name {get; set;}
        
        @AuraEnabled
        public String ABN {get; set;}
        
        @AuraEnabled
        public String Address {get; set;}
    }
    
	@AuraEnabled
    public static AccountInfo lookupABN(String abn) {
        ABNLookupStub.AustralianBusinessNumber data = ABNLookupStub.ABRSearchByABN(abn);
        System.debug(data);
        
        if ((data != null) && ((data.isInvalid == null) || !data.isInvalid) && (data.ABN != null) && (data.name != null)) {            
            return new AccountInfo(data.ABN, data.name, data.isActive, data.Status, data.isInvalid);
        }

        return new AccountInfo();
    }
    
    @AuraEnabled
    public static List<ExistingAccount> duplicateCheck(String name, String abn, String street, String city, String postcode, String state, String country) {
        List<ExistingAccount> existing = new List<ExistingAccount>();
        
        if (String.isBlank(name)) name = '-'; else name = name.trim();
        if (String.isBlank(abn)) abn = '-'; else abn = abn.trim();
        if (String.isBlank(street)) street = '-';
        if (String.isBlank(city)) city = '-';
        if (String.isBlank(postcode)) postcode = '-';
        if (String.isBlank(state)) state = '-';
        if (String.isBlank(country)) country = '-';
        
        for (Account acc: [SELECT Id, Name, AccountNumber, Primary_Address__c FROM Account WHERE (Name = :name) OR (AccountNumber = :abn) OR ((BillingStreet = :street) AND (BillingStreet = :street) AND (BillingCity = :city) AND (BillingPostalCode = :postcode) AND (BillingState = :state) AND (BillingCountry = :country))]) {
            ExistingAccount ex = new ExistingAccount();
            
            ex.Id = acc.Id;
            ex.Link = '/' + acc.Id;
            ex.Name = acc.Name;
            ex.ABN = acc.AccountNumber;
            ex.Address = acc.Primary_Address__c;
            
            existing.add(ex);
        }
        
        return existing;
    }
    
    @AuraEnabled
    public static List<AT_RecordTypeUtil.RecordTypeInfo> getRecordTypes() {
        return AT_RecordTypeUtil.getRecordTypes('Account');
    }
    
    @AuraEnabled
    public static String lookupAddress(String address, String sourceOfTruth) {
        datasan__Setting__c setting = [SELECT datasan__Key__c FROM datasan__Setting__c LIMIT 1];
        
        Http h = new Http();
       
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://hosted.mastersoftgroup.com/harmony/rest/au/address?sourceOfTruth=' + sourceOfTruth + '&featureOptions=exposeAttributes:1&fullAddress=' + EncodingUtil.urlEncode(address, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Basic ' + setting.datasan__Key__c);
        
        HttpResponse res = h.send(req);
        
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            return '{"status": "ERROR", "messages": "' + res.getStatus() + '", "payload": "' + res.getBody().escapeEcmaScript() + '"}';
        }
    }
}