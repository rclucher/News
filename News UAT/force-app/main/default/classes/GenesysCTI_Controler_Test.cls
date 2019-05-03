/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * Author: Karlis Zemitis
 * Company: Genesys
 * Description: This test class is for GenesysCTI_Controler
 * History:
 * 29/10/2013  Karlis Zemitis Created
 ---------------------------------------------------------*/
@isTest
public class GenesysCTI_Controler_Test{
    

     
        
    static testMethod void CreateCase() {        
        List<Account> accounts = TestDataFactory.CreateAccounts(1,false);
        insert accounts;
    
        List<Contact> contacts = TestDataFactory.CreateContacts(1,accounts[0]);
        insert contacts;
        
        //inbound call all data for case
        String caseId = GenesysCTI_Controler.CreateCase(1, '5115', '12asID3312', String.join(contacts,','), String.join(accounts,','));        
        System.AssertNotEquals(caseId, '');  
        
        //inbound call all data for case no cli
        caseId = GenesysCTI_Controler.CreateCase(1, '', '12asID3312', String.join(contacts,','), String.join(accounts,','));        
        System.AssertNotEquals(caseId, '');  
        
        // inbound call no account for case
        caseId = GenesysCTI_Controler.CreateCase(1, '5115', '12asID3312', String.join(contacts,','), '');        
        System.AssertNotEquals(caseId, '');    
        
        // inbound call no contact
        caseId = GenesysCTI_Controler.CreateCase(1, '5115', '12asID3312', '', String.join(accounts,','));        
        System.AssertNotEquals(caseId, '');   
        
        // inbound call  no contact or account 
        caseId = GenesysCTI_Controler.CreateCase(1, '5115', '12asID3312', '', '');        
        System.AssertNotEquals(caseId, '');       

        // otubound call 
        caseId = GenesysCTI_Controler.CreateCase(2, '5115', '12asID3312', '', '');        
        System.AssertNotEquals(caseId, '');
        
        // otubound call  no cli
        caseId = GenesysCTI_Controler.CreateCase(2, '', '12asID3312', '', '');        
        System.AssertNotEquals(caseId, '');
        
        //create task inbound
        String retJson= GenesysCTI_Controler.CreateTask(1, '045673434', caseId, 'Case', 1383018440544L, 1383018450289L, 9, '010a0233d62141b9', true);        
        System.AssertNotEquals(retJson, '');  
        
        //create task outbound
        retJson= GenesysCTI_Controler.CreateTask(2, '045673434', caseId, 'Case', 1383018440544L, 1383018450289L, 9, '010a0233d62141b9', true);        
        System.AssertNotEquals(retJson, '');  
        
        //create task outbound not answered
        retJson= GenesysCTI_Controler.CreateTask(2, '045673434', caseId, 'Case', 1383018440544L, 1383018450289L, 9, '010a0233d62141b9', false);        
        System.AssertNotEquals(retJson, '');     
        
        //create email
        retJson= GenesysCTI_Controler.CreateTask(3, '045673434', caseId, 'Case', 1383018440544L, 1383018450289L, 9, '010a0233d62141b9', true);        
        System.AssertNotEquals(retJson, '');    

        String ret = GenesysCTI_Controler.SetCaseOwner(caseId);
        System.AssertEquals(ret, caseId);
    }  
}