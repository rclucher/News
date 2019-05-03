/*---------------------------------------------------------
 * Author: Logabalakrishnan (LBK) Muthukrishnan
 * Company: News
 * Description: 
 * 1. This class is for Requirement: Item-01273.
 *              The purpose of this class is to develope a Quick Action popup functionality 
 * 				with ability to choose opportunity RecordType dynamically,  
 *              from within Account page.
 * History:
 * 2018-03-16   LBK     Created
 ---------------------------------------------------------*/
public with sharing class clsCreateOpportunityExtension {
    public final SObject objAccount;
    public Opportunity objNewOpportunity {get; set;}
    public String sErrorMessage {get; set;}
    public String selectedRecordType = null;
    public String selectedRecordTypeName {get; set;}
    public boolean bRecordTypeSelected {get; set;}
    public string sSavedOpportunity {get; set;}
    
    public clsCreateOpportunityExtension(ApexPages.StandardController controller) {
        objAccount = controller.getRecord();
        sErrorMessage = '';
        
        system.debug('constructor called');
        system.debug('bRecordTypeSelected : ' + bRecordTypeSelected);
        system.debug('selectedRecordType : ' + selectedRecordType);
        List<Schema.RecordTypeInfo> lstAvailableRecordTypes = getAvailableRecordTypes();
        
        if(bRecordTypeSelected == null){
            bRecordTypeSelected = false;
        }
        
        if(lstAvailableRecordTypes.size() == 1 && bRecordTypeSelected == false){
            system.debug('only one record type available for the user');
            this.selectedRecordType = lstAvailableRecordTypes[0].getRecordTypeId();
            //this.selectedRecordTypeName = ' : ' + lstAvailableRecordTypes[0].getName();
            PageReference pr = createOpportunity();
        }
        
    }
      
    public PageReference createOpportunity() {
        System.debug('createOpportunity entered');
        bRecordTypeSelected = true;
        this.selectedRecordTypeName =  ' : ' + Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(selectedRecordType).getName();
        objNewOpportunity = new Opportunity();
        objNewOpportunity.accountId = objAccount.id;
        objNewOpportunity.RecordTypeId = selectedRecordType;
        return ApexPages.currentPage();
    }
       
     public void saveOpportunity() {      
        try {
            sErrorMessage = '';
            System.debug('saveOpportunity entered');
            Database.SaveResult srOpportunity = Database.insert(objNewOpportunity, false);
        	System.debug('srOpportunity.isSuccess() : ' + srOpportunity.isSuccess());
            if(!srOpportunity.isSuccess()){
                for(Database.Error err : srOpportunity.getErrors()) {
                    System.debug('The following error has occurred.');                   
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                    if(sErrorMessage != ''){
                        sErrorMessage += ', ';
                    }
                    sErrorMessage += err.getMessage();
        		}
            }
            else{
                sSavedOpportunity = objNewOpportunity.Name;
            }
        } catch(System.Exception ex){
           sErrorMessage = ex.getMessage();
           System.debug(ex.getMessage());
        }
        
    }

	public List<SelectOption> getRecordTypes() {
        List<SelectOption> options = new List<SelectOption>();
        List<Schema.RecordTypeInfo> lstRecordTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfos();
        
		for(Schema.RecordTypeInfo objRecordTypeInfo : lstRecordTypeInfo){
			if(objRecordTypeInfo.isAvailable() == true && objRecordTypeInfo.isMaster() == false){
				options.add(new SelectOption(objRecordTypeInfo.getRecordTypeId(), objRecordTypeInfo.getName()));	
			}
		}
        return options;
    }
    
    private List<Schema.RecordTypeInfo> getAvailableRecordTypes(){
        List<Schema.RecordTypeInfo> lstAvailableRecordTypes = new List<Schema.RecordTypeInfo>();
        List<Schema.RecordTypeInfo> lstRecordTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfos();
        for(Schema.RecordTypeInfo objRecordTypeInfo : lstRecordTypeInfo){
            if(objRecordTypeInfo.isAvailable() == true && objRecordTypeInfo.isMaster() == false){
                lstAvailableRecordTypes.add(objRecordTypeInfo);
			}
		}
        return lstAvailableRecordTypes;
    }
    
	public String getSelectedRecordType() {
        return selectedRecordType;
    }
    public void setSelectedRecordType(String selectedRecordType) { this.selectedRecordType = selectedRecordType; }

}