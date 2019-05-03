/** 
 *
 * @author      Paul Kang, Bluewolf 
 * @description Batch Apex to process from Portfolio_Account_Staging__c to 
 * @description Modified 2018-02-05 Paul Kang 
 *				Updated 2018-03-09 Paul Kang - Updated to only filter the Master Objects based on the items in Scope
 * @description Updating the External ID field to cater the future updates of New Portfolio Code
 * 				Modified 2018-10-11 Pratyush. Refer to Jira: NR-1364
 * 				Modified 2018-10-11 Mohsin Ali. Refer to Jira: NR-1364
 * @description Adding the condition to check in Acct_SFDC_ID__c
 * 				Modified 2018-11-14 Mohsin Ali.Refer to Jira: NR-1964
 * @description Truncating Portfolio_Account_Staging__c.Account_Name__c to 69 characters.
 *				Modified 2019-03-19 David Scullion. Refer to Jira: SFE-976
 **/

global class PortfolioAccountMappingProcess implements Database.Batchable<sObject>, Database.Stateful {
	String query = 'SELECT Account_Name__c,Account_Number__c,Account_Source_Type__c,External_ID__c,Name,New_Portfolio_Code__c,Old_Portfolio_Code__c,Portfolio_End_Date__c,Portfolio_Start_Date__c,Relationship_Type__c FROM Portfolio_Account_Staging__c WHERE IsDeleted = false';
	global Map<String,Id> acctSFCE {get;set;}
	global Map<String,Id> acctADPT {get;set;}
	global Map<String,Id> portfolios {get;set;}
	global Map<String,Id> bsaGNRA {get;set;}

	public Integer bSAJunctionCount;
	public Integer acctJunctionCount;

 	global Boolean deleteStagingOnComplete {get; set;}
    public Boolean sendEmailIfStagingEmpty {get; set;}
    public String primaryEmailAddress {get;set;}
    public String secondaryEmailAddress {get;set;}


    private final string adPointSourceType = 'ADPT';
    private final string saleforceSourceType = 'SFCE';
    private final string generaSourceType = 'GNRA';


		// Check the custom meta data settings configuration
	private void loadMDT() {
		List<Portfolio_Process_Settings__mdt> settings = [SELECT Id, Label, Delete_Staging_on_complete__c, Send_Email_when_staging_is_empty__c, Primary_alert_email_address__c, Secondary_alert_email_address__c FROM Portfolio_Process_Settings__mdt where Label ='Default'];

		System.debug('@settings ' + settings);
		deleteStagingOnComplete = Boolean.valueOf(settings[0].Delete_Staging_on_complete__c);
		sendEmailIfStagingEmpty = Boolean.valueOf(settings[0].Send_Email_when_staging_is_empty__c);
		primaryEmailAddress = settings[0].Primary_alert_email_address__c;
		secondaryEmailAddress = settings[0].Secondary_alert_email_address__c;
	}
	


	// Constructor to load all the Map in memory 
	global PortfolioAccountMappingProcess() {
		acctADPT = new Map<String,Id>();
		acctSFCE = new Map<String,Id>();
		bsaGNRA = new Map<String,Id>();
		portfolios = new Map<String,Id>();
		bSAJunctionCount = 0;
		acctJunctionCount = 0;
	}


	global Database.QueryLocator start(Database.BatchableContext bC) {		
		return Database.getQueryLocator(query);
	}


   	global void execute(Database.BatchableContext bC, List<Portfolio_Account_Staging__c> scope) {

   		List<Account_Portfolio_Relationship__c> acctPortList = new List<Account_Portfolio_Relationship__c>();
   		List<Booking_System_Portfolio_Junction__c> bookPortList = new List<Booking_System_Portfolio_Junction__c>();

   		// With the scope given get the 
   		List<String> portfolioAccountStagingAccountNumber = new List<String>();
   		List<String> externalAccountsGBA = new List<String>();
   		List<String> portfolioStagingPortfolioCodes = new List<String>();

   		// Filter based on the scope on which Accounts or External_Account__c to filter
		for(Portfolio_Account_Staging__c pas : scope) {
			if (pas.Account_Source_Type__c == adPointSourceType || pas.Account_Source_Type__c == saleforceSourceType) {
				portfolioAccountStagingAccountNumber.add(pas.Account_Number__c);
			}
			else if (pas.Account_Source_Type__c == generaSourceType) {
				externalAccountsGBA.add(pas.Account_Number__c);
			}
			portfolioStagingPortfolioCodes.add(pas.New_Portfolio_Code__c);
		}


		// Filter the Accounts based on the External Ids passed in scope
		Map<ID,Account> adptMap = new Map<ID,Account>([SELECT Id, Acct_SFDC_ID__c, AdPoint_Id__c from Account where (AdPoint_Id__c IN :portfolioAccountStagingAccountNumber OR Acct_SFDC_ID__c IN :portfolioAccountStagingAccountNumber) and IsDeleted = false]);
		
		// Load All Account Maps both SFCE and ADPT
		for(Id idKey : adptMap.keySet() ) {
			Account acct = adptMap.get(idKey);
			if (acct.AdPoint_Id__c != null) {
				// add to map
				acctADPT.put(acct.AdPoint_Id__c, Acct.Id);
			}
			acctSFCE.put(acct.Acct_SFDC_ID__c, Acct.Id);
		}


		// Filter the External Accounts based on the External Ids passed in scope
		Map<Id, External_Account__c> bsaMap = new Map<Id,External_Account__c>([Select Id, External_ID__c from External_Account__c where External_ID__c IN:externalAccountsGBA and IsDeleted = false]);

		// Load all Booking System Account for GNRA i.e. GBA_T... 
		for(Id idKey : bsaMap.keySet()) {
			External_Account__c bsa = bsaMap.get(idKey);
			bsaGNRA.put(bsa.External_Id__c, bsa.Id);
		}


		// Filter the Portfolios to load 
		Map<Id, Portfolio2__c> portMap = new Map<Id,Portfolio2__c>([Select Id, Portfolio_Code__c from Portfolio2__c where Portfolio_Code__c IN: portfolioStagingPortfolioCodes AND IsDeleted = false]);

		for(Id idKey: portMap.keySet()) {
			Portfolio2__c port = portMap.get(idKey);
			portfolios.put(port.Portfolio_Code__c, port.Id);
		}

   		try {

			if (scope.size() > 0) {
		 		for(Portfolio_Account_Staging__c pas : scope) {			

					// truncate the Account Name to 69 characters
					String ac = pas.Account_Name__c;
					String ac2 = ac.abbreviate(69);

					// check the source type
					if (pas.Account_Source_Type__c == saleforceSourceType || pas.Account_Source_Type__c == adPointSourceType) {
                        Id res =getAccountId(pas.Account_Number__c, pas.Account_Source_Type__c);
						if (res == null) {
							// no matching account found
							System.debug('@No matching Account found for' + pas.Account_Name__c);
							continue;	
						} 
						else {
							System.debug('@Account match found ' + res);
							Account_Portfolio_Relationship__c acctPort = new Account_Portfolio_Relationship__c();
							// Add to the Account Junction
							acctPort.Account__c = res;
							acctPort.ExternalID__c = pas.External_ID__c;
							//acctPort.Name = pas.Account_Name__c + '|' + pas.New_Portfolio_Code__c;
							acctPort.Name = ac2 + '|' + pas.New_Portfolio_Code__c;
							acctPort.Portfolio__c = portfolios.get(pas.New_Portfolio_Code__c);
							acctPort.Relationship_Type__c = pas.Relationship_Type__c;
							acctPort.Start_Date__c = pas.Portfolio_Start_Date__c;
							acctPort.End_Date__c = pas.Portfolio_End_Date__c;
							//SFE-1058
							//acctPort.New_External_ID__c = pas.External_ID__c.substring(0, pas.External_ID__c.indexOf('|')) + '|' + pas.Relationship_Type__c + '|' + pas.New_Portfolio_Code__c;
                            
							acctPortList.add(acctPort);

							acctJunctionCount += 1;
                            
                            
						}
					}
					else if (pas.Account_Source_Type__c == generaSourceType) {
						Id res = getAccountId(pas.Account_Number__c, pas.Account_Source_Type__c);
						if (res == null) {
							System.debug('@no matching Booking System account found ' + pas.Account_Name__c);
							continue;
						}
						else {
							System.debug('@Booking System Account match found in Staging' + res);
							Booking_System_Portfolio_Junction__c bsa = new Booking_System_Portfolio_Junction__c();
							bsa.BSA_Portfolio_Id__c = pas.External_ID__c;
							//bsa.Name = pas.Account_Name__c + '|' + pas.New_Portfolio_Code__c;
							bsa.Name = ac2 + '|' + pas.New_Portfolio_Code__c;
							bsa.Booking_System_Account__c = res;
							bsa.Portfolio__c = portfolios.get(pas.New_Portfolio_Code__c);
							bsa.Relationship_Type__c = pas.Relationship_Type__c;
							bsa.Start_Date__c = pas.Portfolio_Start_Date__c;
							bsa.End_Date__c = pas.Portfolio_End_Date__c;
                            
                            /*Adding values to a New Temporary Field and then populating back in the ExternalID Field Using For Loop After Upsert*/
                            //SFE-1058
							//bsa.New_BSA_Portfolio_Id__c	= pas.External_ID__c.substring(0, pas.External_ID__c.indexOf('|')) + '|' + pas.Relationship_Type__c + '|' + pas.New_Portfolio_Code__c;

							bookPortList.add(bsa);

							bSAJunctionCount += 1;
						}
					}	
					else {
						// flag error of unknown source Type
						System.debug('Incorrect Source Type: ' + pas.Account_Source_Type__c);
						continue;
					}
				}

					upsert acctPortList ExternalID__c;
					upsert bookPortList BSA_Portfolio_Id__c;
					
                
                			/*Adding values to a New Temporary Field and then populating back in the ExternalID Field Using For Loop After Upsert*/
                	//SFE-1058 Begins
					//for (Account_Portfolio_Relationship__c apr: acctPortList) apr.ExternalID__c = apr.New_External_ID__c;
                	//for (Booking_System_Portfolio_Junction__c bspj: bookPortList) bspj.BSA_Portfolio_Id__c = bspj.New_BSA_Portfolio_Id__c;
					//SFE-1058 Ends               
                			/*Updating External ID field with the New External ID field for future lookup.*/
                	update acctPortList;
                	update bookPortList;
				}
				else {
					//alert data services team
					String[] toAddresses = new String[]{ primaryEmailAddress, secondaryEmailAddress };

		   			Batch_Utility.sendEmail(toAddresses, 'No records loaded from Staging object','PortfolioProcess failed, Portfolio_Account_Staging__c is empty');
				}
			}
		catch(Exception ex) {
			ExLog.log(ex, 'config', (SObject)null, '');   	
		}
	}




	// Get value of Ids from constructor loaded Maps
	@TestVisible
	private Id getAccountId(string accountNo, string sourceType) {
		Id res;
		if (sourceType == saleforceSourceType) {
			res = acctSFCE.get(accountNo);
		}
		else if (sourceType == adPointSourceType) {
			res = acctADPT.get(accountNo);
		}
		else if (sourceType == generaSourceType) {
			res = bsaGNRA.get(accountNo);
		}
		return res;

	}
	
	
	global void finish(Database.BatchableContext bC) {
	   // Get the ID of the AsyncApexJob representing this batch job
	   // from Database.BatchableContext.
	   // Query the AsyncApexJob object to retrieve the current job's information.
	   AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
	      TotalJobItems, CreatedBy.Email
	      FROM AsyncApexJob WHERE Id =
	      :bC.getJobId()];
	   // Send an email to the Apex job's submitter notifying of job completion.

		string subject = 'PortfolioProcess ' + a.Status;
		string body = 'The batch PortfolioProcess job processed ' + a.TotalJobItems +
	   ' batches with '+ a.NumberOfErrors + ' failures.\n' 
	   + ' Booking_System_Portfolio_Junction__c upserted: ' + bSAJunctionCount + '\n'
	   + ' Account_Portfolio_Relationship__c upserted: ' + AcctJunctionCount; 
		String[] toAddresses = new String[] {a.CreatedBy.Email};

		Batch_Utility.sendEmail(toAddresses,subject,body);

		//
		if (deleteStagingOnComplete == true) {
			Database.executeBatch(new BatchDeleteProcess(), 2000);
		}
		//SFE-1058 Begins
		if(a.TotalJobItems>0 && a.NumberOfErrors==0){
		AccountPortfolioRelationshipBatch apBatch = new AccountPortfolioRelationshipBatch();
		Database.executeBatch(apBatch);

		BookingSystemPortfolioJunctionBatch bsBatch = new BookingSystemPortfolioJunctionBatch();
		Database.executeBatch(bsBatch);
		}
		//SFE-1058 Ends

	}

	
}