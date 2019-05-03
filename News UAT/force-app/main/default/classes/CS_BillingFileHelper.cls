/**
 * Creates billing file for current month and associates 
 */
public class CS_BillingFileHelper {

	/**
	 * Creates billing file for current month
	 * Naming convention - {Month Name} {Year}
	 */
	public static void createBillingFile(Datetime dt) {
		String fileName= dt.format('MMMMM') + ' ' + dt.year();
		List<Billing_File__c> bfList = [
			select id, name
			from Billing_File__c
			where name = :fileName
		];
		Billing_File__c bf;
		if (bfList.isEmpty()) {
			bf = new Billing_File__c();
			bf.name = fileName;
			bf.Status__c = 'Pending';
			bf.Billing_Date__c = dt.date().addMonths(1).toStartofMonth().addDays(-1);
			insert bf;
		}
	}
	
	/**
	 * Associates all Payment Schedules with billing date in this month with billing file
	 * Changes status of all payment schedules to Scheduled
	 */
	public static void associatePaymentSchedulesToBillingFile(Datetime dt) {
		
		String fileName= dt.format('MMMMM') + ' ' + dt.year();
		List<Billing_File__c> bfList = [
			select id, name, Status__c
			from Billing_File__c
			where name = :fileName
		];
        system.debug('fileName-->'+fileName);
        system.debug('bfList-->'+bfList);
        system.debug('dt-->'+dt);
		if (!bfList.isEmpty() && bfList[0].Status__c != 'Sent To Billing') {
			Date dateFilter = dt.date().addMonths(1).toStartofMonth().addDays(-1);
			List<Payment_Schedule__c> psList = [				
                select id, name, Status__c				
                from Payment_Schedule__c				
                where Billing_Date__c = :dateFilter
				and (Status__c = 'Pending' or Status__c = 'In Progress')
			];
            system.debug('dateFilter-->'+dateFilter);
            system.debug('psList-->'+psList);
			List<PS_Billing_File_Association__c> oldAssociations = [
				select id
				from PS_Billing_File_Association__c
				where Billing_File__c = :bfList[0].Id
			];
            system.debug('oldAssociations-->'+oldAssociations);
			if (!oldAssociations.isEmpty()) {
				delete oldAssociations;
			}
			List<PS_Billing_File_Association__c> associations = new List<PS_Billing_File_Association__c>();
			for (Payment_Schedule__c ps : psList) {
				PS_Billing_File_Association__c assoc = new PS_Billing_File_Association__c();
				assoc.Payment_Schedule__c = ps.Id;
				assoc.Billing_File__c = bfList[0].Id;
				associations.add(assoc);
				ps.Status__c = 'Scheduled';
			}
            system.debug('associations-->'+associations);
			if (!associations.isEmpty()) {
				insert associations;
				Billing_File__c bf = bfList[0];
				Database.SaveResult[] srList = Database.update(psList, false);
				Boolean updateBf = false;
				for (Database.SaveResult sr : srList) {
					if (!sr.isSuccess()) {
						bf.Status__c = 'Error';
						for (Database.Error err : sr.getErrors()) {
							bf.Error_Message__c += err.getMessage() + ' ';
						}
						bf.Error_Message__c += '\n';
						updateBf = true;
					}
				}
				if (updateBf) {
					update bf;
				}
			}
		
		}
		
	}
	
	public class MyException extends Exception {}


}