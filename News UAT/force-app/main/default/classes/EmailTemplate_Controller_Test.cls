/**
 * This class contains unit tests for validating the behavior of Apex classes 'EmailTemplate_Controller'
 * and triggers.
 *
 * History:
 * 19/10/2013  Bohao Chen  Created
 * ---------------------------------------------------------*/
@isTest
private class EmailTemplate_Controller_Test 
{
    static testMethod void emailTemplateComponentTest() 
    {

    	list<Division_Info__c> dis = TestDataFactory.createDivisionInformation();
    	insert dis;


    	EmailTemplate_Controller controller = new EmailTemplate_Controller();

		controller.divisionName = dis[0].Name;


		id folderId = [Select Id from Folder where Name='Logos & Identity' limit 1].id; 


		Document doc = new Document();
		doc.AuthorId = UserInfo.getUserId();
		doc.FolderId = folderId;
		doc.name = dis[0].Name + ' Logo';
		doc.body = Blob.valueOf('My image');
		insert doc;

		String logoId = controller.getLogoId();

		String orgId = controller.getOrgId();

		String divAddress = controller.getDivisionAddress();
		System.Assert(divAddress == dis[0].Address__c);


		String switchboard = controller.getSwitchboard();
		System.Assert(switchboard == dis[0].SwitchBoard__c);	
		

		String abn = controller.getAbn();
		System.Assert(abn == dis[0].Abn__c);


		String disclaimer = controller.getDisclaimer();
		System.Assert(disclaimer == dis[0].Disclaimer__c);		


		controller.divisionName = 'invalid division name';
		try{
			divAddress = controller.getDivisionAddress();
		}catch(Exception ex){
			System.Assert(divAddress == null);
		}

		try{
			switchboard = controller.getSwitchboard();
		}catch(Exception ex){
			System.Assert(switchboard == null);
		}

 		try{
			abn = controller.getAbn();
		}catch(Exception ex){
			System.Assert(abn == null);
		}       
   
 		try{
			disclaimer = controller.getDisclaimer();
		}catch(Exception ex){
			System.Assert(disclaimer == null);
		}      
    }
}