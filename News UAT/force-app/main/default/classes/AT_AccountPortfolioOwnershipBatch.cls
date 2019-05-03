@RestResource(urlMapping = '/AccountPortfolioOwnership/*')
global without sharing class AT_AccountPortfolioOwnershipBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	global void execute(SchedulableContext sc) {
		AT_AccountPortfolioOwnershipBatch batch = new AT_AccountPortfolioOwnershipBatch();

		Database.executeBatch(batch, 50);
	}

	global class UpdateResponse {
		public Integer changed { get; set; }
		public Integer updated { get; set; }
		public Integer failed { get; set; }
	}

	@HttpGet
	global static List<Id> getAccountIDs() {
		AT_AccountPortfolioOwnershipBatch batch = new AT_AccountPortfolioOwnershipBatch();

		return new List<Id> (batch.findRelevantAccounts());
	}

	@HttpPost
	global static UpdateResponse updateAccounts(List<String> accountsToUpdate) {
		System.debug('Updating: ' + accountsToUpdate);

		AT_AccountPortfolioOwnershipBatch batch = new AT_AccountPortfolioOwnershipBatch();

		List<Account> accounts = [SELECT Id, Type, Customer_Segment__c, OwnerId, Owner.ProfileId FROM Account WHERE(Id IN :accountsToUpdate)];

		batch.initialiseState();

		return batch.updateAccounts(accounts);
	}

	public Id unassigned, vacant, theAusSalesId;

	public Set<Id> portfoliosWithMultipleOwners = new Set<Id> ();

	Map<Id, Portfolio2__c> portfolioMap;

	// Find all accounts to process, and initialise datastructures which will be used during batch execution
	public Database.QueryLocator start(Database.BatchableContext bC) {
		initialiseState();

		return Database.getQueryLocator([SELECT Id, Type, Customer_Segment__c, OwnerId, Owner.ProfileId FROM Account WHERE(Id IN :findRelevantAccounts())]);
	}

	public Set<Id> findRelevantAccounts() {
		Set<Id> accountIDs = new Set<Id> ();

		//        for (Account acc: [SELECT Id FROM Account WHERE (Id IN (SELECT Account__c FROM Account_Portfolio_Relationship__c WHERE LastModifiedDate = TODAY))]) {
		for (Account acc :[SELECT Id FROM Account WHERE(Id IN(SELECT Account__c FROM Account_Portfolio_Relationship__c WHERE(Portfolio__r.LastModifiedDate = TODAY OR LastModifiedDate = TODAY)))]) {
			accountIDs.add(acc.Id);
		}

		//        for (Account acc: [SELECT Id FROM Account WHERE (Id IN (SELECT Account__c FROM Booking_System_Portfolio_Junction__c WHERE LastModifiedDate = TODAY))]) {
		for (Account acc :[SELECT Id FROM Account WHERE(Id IN(SELECT Account__c FROM Booking_System_Portfolio_Junction__c WHERE(Portfolio__r.LastModifiedDate = TODAY OR LastModifiedDate = TODAY)))]) {
			accountIDs.add(acc.Id);
		}

		return accountIDs;
	}

	public void initialiseState() {
		portfolioMap = new Map<Id, Portfolio2__c> ([SELECT Id, Name, Portfolio_Code__c, Portfolio_Segment__c, Priority_Sequence__c, (SELECT Portfolio_Owner__c, Portfolio_Owner__r.Name FROM Portfolio_Teams__r) FROM Portfolio2__c]);

		for (User u :[SELECT Id, FirstName, LastName FROM User WHERE(LastName = 'NextG') AND(FirstName IN('Unassigned', 'Vacant'))]) {
			if (u.FirstName == 'Unassigned') unassigned = u.Id;
			if (u.FirstName == 'Vacant') vacant = u.Id;
		}

		theAusSalesId = [SELECT Id FROM Profile WHERE Name = 'The Aus Sales'].Id;
	}

	public void execute(Database.BatchableContext bC, List<sObject> scope) {
		updateAccounts(scope);
	}

	public UpdateResponse updateAccounts(List<SObject> scope) {
		Map<Id, Set<Id>> accountPortfoliosMap = new Map<Id, Set<Id>> ();

		for (Booking_System_Portfolio_Junction__c rel :[SELECT Account__c, Portfolio__c FROM Booking_System_Portfolio_Junction__c WHERE(Account__c IN :scope) AND(Delete_Flag__c = false)]) {
			Set<Id> portfolioIDs = accountPortfoliosMap.get(rel.Account__c);

			if (portfolioIDs == null) portfolioIDs = new Set<Id> ();

			portfolioIDs.add(rel.Portfolio__c);

			accountPortfoliosMap.put(rel.Account__c, portfolioIDs);
		}

		for (Account_Portfolio_Relationship__c rel :[SELECT Account__c, Portfolio__c FROM Account_Portfolio_Relationship__c WHERE(Account__c IN :scope) AND(Delete_Flag__c = false)]) {
			Set<Id> portfolioIDs = accountPortfoliosMap.get(rel.Account__c);

			if (portfolioIDs == null) portfolioIDs = new Set<Id> ();

			portfolioIDs.add(rel.Portfolio__c);

			accountPortfoliosMap.put(rel.Account__c, portfolioIDs);
		}

		List<Account> updatedAccounts = new List<Account> ();

		// Go through each Account one by one and look at the Portfolios linked to it, and their Owners
		for (Account acc : (List<Account>) scope) {
			Integer updates = 0;
			Integer noOwnerCount = 0;

			System.debug('Processing account: ' + acc.Id);

			Set<Id> portfolioIDs = accountPortfoliosMap.get(acc.Id);

			System.debug('Portfolios: ' + portfolioIDs);

			if (portfolioIDs == null || portfolioIDs.isEmpty()) {
				// If this account does not have any portfolios attached then mark it as "Non Account Managed" and owned by Unassigned ???
				updates += updateIfChanged(acc, 'Type', mapType(acc.Type, 'Non Account Managed'));
				updates += updateIfChanged(acc, 'OwnerId', unassigned);

				System.debug('No portfolios');
			} else if (portfolioIDs != null && !portfolioIDs.isEmpty()) {
				if (portfolioIDs.size() == 1) {
					System.debug('1 portfolio');

					// If there's only 1 Portfolio for the Account...
					Portfolio2__c portfolio = portfolioMap.get(new List<Id> (portfolioIDs) [0]);

					if (portfolio.Portfolio_Teams__r.isEmpty()) {
						System.debug('No owners');
						// If there are no Owner records for this Portfolio then mark the Account as "Account Managed" and owned by Vacant
						updates += updateIfChanged(acc, 'Type', mapType(acc.Type, 'Account Managed'));
						updates += updateIfChanged(acc, 'OwnerId', vacant);
					} else if (portfolio.Portfolio_Teams__r.size() == 1) {
						System.debug('1 owner');

						if (portfolio.Portfolio_Teams__r[0].Portfolio_Owner__c == unassigned) {
							System.debug('Unassigned owner, Non Account Managed');
							// If there's only 1 owner and it is the NextG Unnassigned user, then mark the Account as "Non Account Managed"
							updates += updateIfChanged(acc, 'Type', mapType(acc.Type, 'Non Account Managed'));
						} else {
							System.debug('Account Managed');
							// Otherwise mark the Account as "Account Managed"
							updates += updateIfChanged(acc, 'Type', mapType(acc.Type, 'Account Managed'));
						}

						System.debug('Assigning owner: ' + portfolio.Portfolio_Teams__r[0].Portfolio_Owner__c);

						// Set the Account Owner to whoever the Portfolio Owner is
						updates += updateIfChanged(acc, 'OwnerId', portfolio.Portfolio_Teams__r[0].Portfolio_Owner__c);
					} else {
						System.debug('More than 1 portfolio');
						// Portfolios should not have more than 1 owner, add this to error collection
						portfoliosWithMultipleOwners.add(portfolio.Id);
					}
				} else {
					Set<Id> ownerIDs = new Set<Id> ();

					for (Id portfolioID : portfolioIDs) {
						Portfolio2__c portfolio = portfolioMap.get(portfolioID);

						//if (portfolio.Portfolio_Teams__r.size() > 1) {
						//	System.debug('More than 1 portfolio');
						// Portfolios should not have more than 1 owner, add this to error collection
						//	portfoliosWithMultipleOwners.add(portfolio.Id);
						//} else if (portfolio.Portfolio_Teams__r.size() == 1) {
						//	ownerIDs.add(portfolio.Portfolio_Teams__r[0].Portfolio_Owner__c);
						//}

						if (portfolio.Portfolio_Teams__r.size() > 1) {
							System.debug('More than 1 portfolio');
							// Portfolios should not have more than 1 owner, add this to error collection
							portfoliosWithMultipleOwners.add(portfolio.Id);
						} else if (portfolio.Portfolio_Teams__r.size() == 1) {
							ownerIDs.add(portfolio.Portfolio_Teams__r[0].Portfolio_Owner__c);
						} else if (portfolio.Portfolio_Teams__r.size() == 0) {
							noOwnerCount += 1;
							System.debug('No Owner Count = ' + noOwnerCount);
						}

					}

					if (ownerIDs.isEmpty()) {
						System.debug('Multiple Portfolios with no owners, what to do??');
					}
					/**
					 * @description - Updated as per SFE-1065
					 * @author - David Scullion
					 * @Date - 2019-03-25 
					 */
					//else if (ownerIDs.size() == 1) {
					else if (ownerIDs.size() == 1 && noOwnerCount == 0) {
						Id ownerID = new List<Id> (ownerIDs) [0];

						System.debug('Multiple Portfolios with the same owner');
						updates += updateIfChanged(acc, 'Type', mapType(acc.Type, 'Account Managed'));

						System.debug('Assigning owner: ' + ownerID);
						// Set the Account Owner to whoever the Portfolio Owner is
						updates += updateIfChanged(acc, 'OwnerId', ownerID);
					} else if (ownerIDs.size() == 1 && noOwnerCount > 0) {
						System.debug('Multiple portfolios, some without owners');
						updates += updateIfChanged(acc, 'Type', mapType(acc.Type, 'Multi Managed'));
					} else if (ownerIDs.size() > 1) {
						System.debug('Multiple Portfolios with different owners');
						// If there's more than one portfolio, then mark this Account as Multi-Managed
						updates += updateIfChanged(acc, 'Type', mapType(acc.Type, 'Multi Managed'));
					}
				}

				// Update Account segment based on portfolio
				String accountSegment = null;
				Decimal sequence = 100;

				if (acc.Owner.ProfileId == theAusSalesId) {
					updates += updateIfChanged(acc, 'Customer_Segment__c', 'AUS');
				} else {
					for (Id pId : portfolioIDs) {
						Portfolio2__c p = portfolioMap.get(pId);

						if (p.Priority_Sequence__c<sequence) {
							accountSegment = p.Portfolio_Segment__c;
							sequence = p.Priority_Sequence__c;
						}
					}

					updates += updateIfChanged(acc, 'Customer_Segment__c', accountSegment);
				}
			}

			if (updates> 0) updatedAccounts.add(acc);
		}

		UpdateResponse response = new UpdateResponse();

		response.changed = updatedAccounts.size();
		response.updated = 0;
		response.failed = 0;

		if (!updatedAccounts.isEmpty()) {
			// Disable trigger
			AccountManagement_Trigger_Helper.byPassAccountTrigger = true;

			// Update accounts, but skip over any that throw an error
			Database.SaveResult[] results = Database.update(updatedAccounts, false);

			for (Database.SaveResult sr : results) if (sr.isSuccess()) response.updated++; else response.failed++;

			// Re-enable trigger after update
			AccountManagement_Trigger_Helper.byPassAccountTrigger = false;
		}

		return response;
	}

	public Integer updateIfChanged(SObject record, String fieldName, Object newValue) {
		Object oldValue = record.get(fieldName);

		if (oldValue != newValue) {
			record.put(fieldName, newValue);

			return 1;
		}

		return 0;
	}

	// Don't change the Type of Account if it's Locally Activated
	public String mapType(String originalType, String newType) {
		return(originalType == 'Locally Activated') ? 'Locally Activated' : newType;
	}

	public void finish(Database.BatchableContext bC) {
		if (!portfoliosWithMultipleOwners.isEmpty()) sendErrorEmail();

		deletePortfoliosAndRelationships();
	}

	public void deletePortfoliosAndRelationships() {
		delete[SELECT Id FROM Account_Portfolio_Relationship__c WHERE(LastModifiedDate = TODAY) AND(Delete_Flag__c = true)];
		delete[SELECT Id FROM Booking_System_Portfolio_Junction__c WHERE(LastModifiedDate = TODAY) AND(Delete_Flag__c = true)];
	}

	public void sendErrorEmail() {
		Map<Id, Portfolio2__c> portfolioMap = new Map<Id, Portfolio2__c> ([SELECT Id, Name, Portfolio_Code__c, (SELECT Portfolio_Owner__c, Portfolio_Owner__r.Name FROM Portfolio_Teams__r) FROM Portfolio2__c]);

		Portfolio_Process_Settings__mdt settings = [SELECT Primary_alert_email_address__c FROM Portfolio_Process_Settings__mdt WHERE DeveloperName = 'Default'];

		String table = '<table border="1"><thead><tr><td>Portfolio ID</td><td>Portfolio Name</td><td>Portfolio Code</td><td>Owners</td></tr></thead><tbody>';

		for (Id portfolioID : portfoliosWithMultipleOwners) {
			Portfolio2__c portfolio = portfolioMap.get(portfolioID);

			List<String> owners = new List<String> ();

			for (Portfolio_Owners__c owner : portfolio.Portfolio_Teams__r) {
				owners.add(owner.Portfolio_Owner__r.Name + ' (' + owner.Portfolio_Owner__c + ')');
			}

			table += '<tr><td>' + portfolio.Id + '</td><td>' + portfolio.Name + '</td><td>' + portfolio.Portfolio_Code__c + '</td><td>' + String.join(owners, ', ') + '</td></tr>';
		}

		table += '</tbody></table>';

		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

		email.setToAddresses(new String[] { settings.Primary_alert_email_address__c });
		email.setSubject('Portfolios with multiple owners');
		email.setHtmlBody('The following portfolios have multiple owners in Salesforce:<br/>' + table);

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
	}
}