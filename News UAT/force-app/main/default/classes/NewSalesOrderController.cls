/**********************************************************************************************
Name          : NewSalesOrderController 
Created By    : Malvika Sharma
Created Date  : Oct 3 2016
Description   : Class to create New sales order
-------
History                                                            
-------                                                            
VERSION     AUTHOR              DATE           DETAIL                   
------      ------              -----          -------                
1.1         Malvika Sharma      3-10-2016     Created   
**********************************************************************************************/

public class NewSalesOrderController {
    
    public NewSalesOrderController(ApexPages.StandardSetController controller) {}
    
    public list<Opportunity> opps;   
    public Opportunity oppty;
    public String oppId;
    Set<String> statuses = new Set<String>{'Sent for External Approval', 'Externally Approved', 'Manually Approved'};
    
    
    public pageReference opptyValidation(){
        oppId = ApexPages.currentPage().getParameters().get('Id');
        if(oppId != null){
            list<Opportunity> opps = new list<Opportunity> ([select OpportunityGroup__c, Account.AdPoint_ID__c, Payer_Account__r.AdPoint_ID__c, Account.Is_Digital__c, Payer_Account__r.Is_Digital__c, Account.NEWS_Segment__c, Account.datasan__Account_ABN__c, Account.Customer_Books_Direct__c,Payer_Account__r.name, Account.Name, Contact__r.Email,JDE_Publication_Code__c, TM1_Publication__c,Payer_Account__r.Customer_Books_Direct__c,OwnerId,Owner.Name,(Select id, name, csmso__Booking_Contact__r.Email from csmso__Sales_Orders__r WHERE csmso__Status__c IN :statuses) from Opportunity where id=:oppId limit 1]);
            if (opps != null && opps.size() > 0) {
                oppty = opps[0];
            }
            if(oppty != null){    
            system.debug('accname'+oppty.Account.Name);   
            system.debug('payeraccname'+oppty.Payer_Account__r.name);             
                if(oppty.OpportunityGroup__c != 'NewsXtend'){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Cant create Sales Order. Opportunity Platform must include NewsXtend.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                    return null;
                }else if(oppty.Account.AdPoint_ID__c == null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Cant create Sales Order. Account AdPointID cannot be null.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                    return null;
                }else if(oppty.Payer_Account__r.AdPoint_ID__c == null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Cant create Sales Order. Payer Account AdPointID cannot be null.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                    return null;
                }else if(!oppty.Account.Is_Digital__c){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Cant create Sales Order. Account should be Digital Account.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                    return null;
                }else if(!oppty.Payer_Account__r.Is_Digital__c){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Cant create Sales Order. Payer Account should be Digital Account.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                    return null;
                }
                else if(!oppty.csmso__Sales_Orders__r.isEmpty()){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Cant create Sales Order. Sales orders with Approval Status already exist.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                    return null;
                }
                else if(oppty.JDE_Publication_Code__c == null){
                    
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Cant create the Sales Order. There is no Sales Team assigned on the user profile for the Opportunity Owner '+ oppty.Owner.Name + '.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                    return null;
                   
                }
               
                else if(oppty.TM1_Publication__c== null){
                    
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Cant create Sales Order. TM1 Publication cannot be null.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                    return null;
                	
                }
                else if((oppty.Payer_Account__r.Customer_Books_Direct__c!='Yes') || (oppty.Account.Customer_Books_Direct__c=='Yes' && (oppty.Account.ID != oppty.Payer_Account__r.ID ))){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Cant create the Sales Order. Account and the Payer account combination is invalid. <br>If Account is flagged as Books Direct then Payer Account must be same as Account.<br>If Account is flagged as No to Books Direct then Payer Account must be different and flagged as Books Direct.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                    return null;
                }
                else{
                    if (responseMapping(oppty)) {
                        PageReference acctPage = new PageReference('/apex/Opp2SalesOrder?id='+oppId);
                        acctPage.setRedirect(true);
                        return acctPage;
                    }
                    else {
                        //return null;
                        PageReference acctPage = new PageReference('/'+oppId);
                        acctPage.setRedirect(true);
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'​This Sales Order cannot be created at this time. There is no valid JDE Debtor Account (DA) reference for either the '+oppty.Payer_Account__r.Name+' or the '+oppty.Payer_Account__r.Name+' and '+oppty.Account.Name+' combination. To resolve this error please select a new account or account combination that has a valid JDE Debtor Account (DA).To create a valid DA, the Account Create Process must be followed. This is currently triggered by checking the Digital Account checkbox on the Opportunity screen in Salesforce. Otherwise contact the relevant parties in Finance to have a DA created.<br><br> Please resolve the above error before attempting to create another sales order.<br><br>Note: The list below outlines all validations executed by the system prior to creating a sales order. Please ensure the opportunity details comply with these rules.<br><br>- Opportunity details must contain <b>NewsXtend</b> in Opportunity Platform field on the opportunity.<br>- The Account and Payer Account added to the opportunity must have <b>Is Digital Account</b> checkbox as true and have the <b>AdPoint Id</b> field populated.<br>- Account and Payer must be the same when Account is flagged as Books Direct.<br>- The AdPoint account must have an active DA account.<br>- There cannot be any Sales orders with Status <b>Sent for External Approval</b>, <b>Externally Approved</b> and <b>Manually Approved</b> in the opportunity.<br>- The Opportunity owner must have the sales team field selected​ on their user profile​.'));
                        return null;
                    }                    
                }
            }
            
        }
        return null;
    }
    public pageReference redirectToOppotunity(){
        PageReference acctPage = new PageReference('/'+oppId);
        acctPage.setRedirect(true);
        return acctPage;
    }
    
    public boolean responseMapping(Opportunity opp) {
    
        
                // instantiate the WS instance
                GBALookupService.news_integration_xtend_cloudsense_agencyClient_wsdl_checkAndCreateAgencyClientDA_Port gba_service = new GBALookupService.news_integration_xtend_cloudsense_agencyClient_wsdl_checkAndCreateAgencyClientDA_Port();
                
                gba_service.timeout_x = 120000; // setting the timeout milliseconds
        
                // preparing the HASH , note , these username , password should be in custom setting or custom labels,
                // and the endpoint as well
                
                GBA_DA_Lookup_Integration__c CS = GBA_DA_Lookup_Integration__c.getOrgDefaults();
                
                String username = CS.Username__c;
                String password = CS.Password__c;
                Blob headerValue = Blob.valueOf(username + ':' + password);
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                system.debug(authorizationHeader);
                
                //setting authentication details in request instance
                gba_service.inputHttpHeaders_x = new Map<String,String>();
                gba_service.inputHttpHeaders_x.put('Content-Type','text/xml');
                gba_service.inputHttpHeaders_x.put('Charset','UTF-8');
                
                gba_service.inputHttpHeaders_x.put('Authorization',authorizationHeader);
                //gba_service.inputHttpHeaders_x.put('Content-Type','text/xml');
                //gba_service.inputHttpHeaders_x.put('Charset','UTF-8');
                
                GBALookupService.crmAdPointOrder crmOrderRequest = new GBALookupService.crmAdPointOrder();
                // building the input data for request
                crmOrderRequest.Customer_ID = opp.Account.AdPoint_ID__c;
                crmOrderRequest.Agency_ID = opp.Payer_Account__r.AdPoint_ID__c;
                //crmOrderRequest.Ref_num_2 = opp.csmo__Sales_Orders__r.id;
                //crmOrderRequest.Name = opp.csmso__Sales_Orders__r.Name;
                crmOrderRequest.Segment = opp.Account.NEWS_Segment__c;
                crmOrderRequest.Placer_Contact_Email_c = opp.Contact__r.Email;
                crmOrderRequest.datasan_xAccount_ABN_xc = opp.Account.datasan__Account_ABN__c;
                crmOrderRequest.Customer_Books_Direct_xc = opp.Account.Customer_Books_Direct__c;
                crmOrderRequest.AccountName = opp.Account.Name;
                //GBALookupService.news_integration_xtend_cloudsense_agencyClient_wsdl_checkAndCreateAgencyClientDA_Port objGBALookupService = new GBALookupService.news_integration_xtend_cloudsense_agencyClient_wsdl_checkAndCreateAgencyClientDA_Port();
                system.debug('crmOrderRequest'+crmOrderRequest.AccountName);
                //calling the Service       
                GBALookupService.agencyClientDAResponse response = gba_service.checkAndCreateAgencyClientDA('true', crmOrderRequest);
                if (response !=null ){ // we assume there was a response 
                    if (response.DA!=null && response.DA.trim().length() > 0 ){
                       // there was actually a DA number returned , then allow redirection and open new sales Order_Creation_Date__c                    
                        return true;
                       
                    }else if(response.errorMessage!=null && response.errorMessage.trim().length() > 0 ){
                       // then it means , there was an error.
                       //displayErrorMessageToUser block creation of SalesOrder    
                       opp.Error_Message__c = response.errorMessage;
                       update opp;
                        return false;
                    }
                  
                } 
                return null;
    }
}