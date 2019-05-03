@isTest
private class dev_test {
	
	@isTest static void test_method_one() {
	
		list<Account> accounts = TestDataFactory.createAccounts(10,false);

		insert accounts[5];

		Database.SaveResult[] srList = Database.insert(accounts, false);

		Integer i = 0;
		for (Database.SaveResult sr : srList) {
		    if (!sr.isSuccess()) {  	
		    	accounts[i].addError('Error on insert account - DPID_Primary_Address__c:' + accounts[i].DPID_Primary_Address__c);
		    	system.debug('Error on insert account - DPID_Primary_Address__c:' + accounts[i].DPID_Primary_Address__c);
		    }
			i++;
		}
	}	
	
}