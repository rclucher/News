/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_AppUtility
* @description  This class have utility methods to provide common functionality between NXX2_* classes.
*/
public class NXX2_AppUtility {
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    private static Map<String,Integer> MonthMap = new Map<String,Integer>{
    	'Jan' => 1,
        'Feb' => 2,
        'Mar' => 3,
        'Apr' => 4,
        'May' => 5,
        'Jun' => 6,
        'Jul' => 7,
        'Aug' => 8,
        'Sep' => 9,
        'Oct' => 10,
        'Nov' => 11,
        'Dec' => 12
    };
    private static Map<Integer,String> fullNameOfMonthMap = new Map<Integer,String>{
    	1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December'
    };

    /**
    * @name         : getDependentOptions
    * @description  : returns picklist values with dependent one
    * @createdby    : Kamal Sharma - 8nd Aug 2018
    * @param        : Schema.SObjectField theField, Schema.SObjectField ctrlField
    * @return       : Map<String, List<String>>
    */
    public static Map<String, List<String>> getDependentOptions(Schema.SObjectField theField, Schema.SObjectField ctrlField) {
        // validFor property cannot be accessed via a method or a property,
        // so we need to serialize the PicklistEntry object and then deserialize into a wrapper.
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        // Set up the return container - Map<ControllingValue, List<DependentValues>>
        Map<String, List<String>> objResults = new Map<String, List<String>>();
        List<String> controllingValues = new List<String>();
        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                // For each bit, in order: if it's a 1, add this label to the dependent list for the corresponding controlling value
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        return objResults;
    }
    
    /**
    * @name         : decimalToBinary
    * @description  : Convert decimal to binary representation (alas, Apex has no native method :-(
    *				  eg. 4 => '100', 19 => '10011', etc.
    *				  Method: Divide by 2 repeatedly until 0. At each step note the remainder (0 or 1).
    *				  These, in reverse order, are the binary.
    * @createdby    : Kamal Sharma - 8nd Aug 2018
    * @param        : Integer val
    * @return       : String
    */
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    /**
    * @name         : base64ToBits
    * @description  : Convert base64 to bits
    * @createdby    : Kamal Sharma - 8nd Aug 2018
    * @param        : String validFor
    * @return       : String
    */
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    /**
    * @name         : wrapPicklistEntries
    * @description  : To deserialize picklist values
    * @createdby    : Kamal Sharma - 8nd Aug 2018
    * @param        : List<Schema.PicklistEntry> PLEs
    * @return       : List<PicklistEntryWrapper>
    */
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    
    //wrapper class
    public class PicklistEntryWrapper {
        public String active {get; set;}
        public String defaultValue {get; set;}
        public String label {get; set;}
        public String value {get; set;}
        public String validFor {get; set;}
    }
    
    /**
    * @name         : findObjectNameFromRecordIdPrefix
    * @description  : Fetch Object name from id prefix  
    * @createdby    : Kamal Sharma - 8nd Aug 2018
    * @param        : String recordIdOrPrefix
    * @return       : String
    */
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            Id recordId = recordIdOrPrefix;
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            List<NXX2_GoogleDriveMyAccountsObjectMapping__mdt> threatMappings = [SELECT MasterLabel, 
                                                                                 QualifiedApiName, 
                                                                                 GoogleDriveFolderId__c FROM NXX2_GoogleDriveMyAccountsObjectMapping__mdt  where MasterLabel = :sObjName];
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;
    }
    
    /**
    * @name         : processGoogleDriveResponse
    * @description  : Method to process the response from google drive Files Rest API
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : build the List of NXX2_LightningReqRespModel.GoogleDriveFilesDTO.
    * @param        : String responseBody : Response of Files Rest API
    */
    public Static List<NXX2_LightningReqRespModel.GoogleDriveFilesDTO> processGoogleDriveResponse(String responseBody){
        Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        List<NXX2_LightningReqRespModel.GoogleDriveFilesDTO> gdriveFilesDtoList=new List<NXX2_LightningReqRespModel.GoogleDriveFilesDTO>();
        List<String> googleDriveFileIds = new List<String>();
        for (Object instance : (List<Object>)meta.get('items')){
            data.add((Map<String, Object>) instance);
            Map<String, Object> itemData = (Map<String, Object>) instance;
            NXX2_LightningReqRespModel.GoogleDriveFilesDTO gdriveFilesDTO = new NXX2_LightningReqRespModel.GoogleDriveFilesDTO();
            gdriveFilesDTO.id = String.valueOf(itemData.get('id'));
            googleDriveFileIds.add(gdriveFilesDTO.id);
            gdriveFilesDTO.thumbnailLink = String.valueOf(itemData.get('thumbnailLink'));
            gdriveFilesDTO.title = String.valueOf(itemData.get('title'));
            gdriveFilesDTO.createdDate = String.valueOf(itemData.get('createdDate'));
            gdriveFilesDTO.mimeType = String.valueOf(itemData.get('mimeType'));
            gdriveFilesDTO.embedLink = String.valueOf(itemData.get('embedLink'));
            gdriveFilesDTO.downloadUrl = String.valueOf(itemData.get('webContentLink')); 
            gdriveFilesDtoList.add(gdriveFilesDTO);
        }
        return gdriveFilesDtoList;
    }
    
    /**
    * @name         : processGoogleDriveFileUploadResponse
    * @description  : Method to process the response from google drive Files Rest API for file upload
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : build the List of NXX2_LightningReqRespModel.GoogleDriveFilesDTO.
    * @param        : String responseBody : Response of Files Rest API
    */
    public Static NXX2_LightningReqRespModel.GoogleDriveFilesDTO processGoogleDriveFileUploadResponse(String responseBody){
        Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        NXX2_LightningReqRespModel.GoogleDriveFilesDTO gdriveFilesDTO=new NXX2_LightningReqRespModel.GoogleDriveFilesDTO();
     	List<String> googleDriveFileIds = new List<String>();
        gdriveFilesDTO.id = String.valueOf(meta.get('id'));
        googleDriveFileIds.add(gdriveFilesDTO.id);
        gdriveFilesDTO.thumbnailLink = String.valueOf(meta.get('thumbnailLink'));
        gdriveFilesDTO.title = String.valueOf(meta.get('title'));
        gdriveFilesDTO.createdDate = String.valueOf(meta.get('createdDate'));
        gdriveFilesDTO.mimeType = String.valueOf(meta.get('mimeType'));
        gdriveFilesDTO.embedLink = String.valueOf(meta.get('embedLink'));
        gdriveFilesDTO.downloadUrl = String.valueOf(meta.get('webContentLink'));
        return gdriveFilesDTO;
    }

    /**
    * @name         : getIconName
    * @description  : Method to get icon name for the given sObject
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : string
    * @param        : String sObjectName
    */
    public static string  getIconName(String sObjectName){
        String u; 
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();
        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { tabDesc.addAll(tsr.getTabs()); }
        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sObjectName == tr.getSobjectName() ) {
                if( tr.isCustom() == true ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    u = 'standard:' + sObjectName.toLowerCase();
                }
                break;
            }
        }
        if(u == null){
            for (Schema.DescribeIconResult ir : iconDesc) {
                if (ir.getContentType() == 'image/svg+xml'){
                    u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                    break;
                }
            }
        }
        return u;
    }

	/**
    * @name         : getCustomerTaskListDTO
    * @description  : Convert standard customer activity data into wrapper object
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : NXX2_LightningReqRespModel.customerTaskResponse
    * @param        : List<Customer_Task__c> customerTaskList
    */
    public static NXX2_LightningReqRespModel.customerTaskResponse getCustomerTaskListDTO(List<Customer_Task__c> customerTaskList){
        NXX2_LightningReqRespModel.customerTaskResponse customerTaskResponse = new NXX2_LightningReqRespModel.customerTaskResponse();
        Boolean isUserHasCreateAccessToTask = Customer_Task__c.sObjectType.getDescribe().isCreateable(); 
        String customMetaDataSetForDueDateNofication = 'X2Warning';
        NXX2_CustomerActivityIndicator__mdt nxx2_CustomerActivityIndicator= null;
        List<NXX2_CustomerActivityIndicator__mdt>  configForCustomerActivityList = [SELECT Label, DueDateExceeding_ColorNotification__c, DueDateExceeds_ColorNotification__c,DueDateNotExceeds_ColorNotification__c, Number_Of_Days_For_Warning__c,MasterLabel
                                                                                    FROM NXX2_CustomerActivityIndicator__mdt WHERE DeveloperName = :customMetaDataSetForDueDateNofication];
        if(configForCustomerActivityList!=null && configForCustomerActivityList.size()>0){
            nxx2_CustomerActivityIndicator = configForCustomerActivityList.get(0);
        }
        //Create a DTO to show as list in Component.
        List<NXX2_LightningReqRespModel.CustomerTaskDTO> listOfCustomerTaskDTO = new List<NXX2_LightningReqRespModel.CustomerTaskDTO>();
        if(customerTaskList!=null && customerTaskList.size()>0){
            for(Customer_Task__c customerTask  : customerTaskList){
                NXX2_LightningReqRespModel.CustomerTaskDTO customerTaskDTO = new NXX2_LightningReqRespModel.CustomerTaskDTO();
                customerTaskDTO.id = customerTask.Id;
                customerTaskDTO.Name = customerTask.Name;
                customerTaskDTO.dueDate = String.valueOf(customerTask.Due_Date__c);
                customerTaskDTO.status= customerTask.Status__c;
                customerTaskDTO.Customer_Task = customerTask;
                customerTaskDTO.isUserHasCreateAccessToTask = isUserHasCreateAccessToTask;
                if(customerTask.Due_Date__c!=null){
                    DateTime warningDate = customerTask.Due_Date__c;
                    DateTime dueDateforComparision = customerTask.Due_Date__c;
                    warningDate = warningDate.addDays(Integer.valueOf(nxx2_CustomerActivityIndicator.Number_Of_Days_For_Warning__c));
                    if(Date.today() > warningDate){
                        customerTaskDTO.warningColor = nxx2_CustomerActivityIndicator.DueDateExceeding_ColorNotification__c;
                    }else if(Date.today() > dueDateforComparision){
                        customerTaskDTO.warningColor = nxx2_CustomerActivityIndicator.DueDateExceeds_ColorNotification__c;
                    }else{
                        customerTaskDTO.warningColor = nxx2_CustomerActivityIndicator.DueDateNotExceeds_ColorNotification__c;
                    }
                }
                customerTaskDTO.campaignOrder = customerTask.Campaign_Order__c;
                customerTaskDTO.socialCampaign = customerTask.Social_Campaign__c;
                customerTaskDTO.productOrder = customerTask.Product_Order__c;
                listOfCustomerTaskDTO.add(customerTaskDTO);
            }
        }
        customerTaskResponse.customerTaskDTOList = listOfCustomerTaskDTO; 
        customerTaskResponse.isUserHasCreateAccessToTask = isUserHasCreateAccessToTask;
        return customerTaskResponse;  
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-08-17
    * @description  getAllCommentsLinkedToType : This method will provide all comments related to customer activity type.
    * 				These comments will be used to pre-populate when user selects a perticular type for a customer activity.
    * @param        NA
    * @return       Map<String,String>
    */
	public static Map<String,String> getAllCommentsLinkedToType(){  
        Map<String,String> mapOfTypeAndComments = new Map<String,String>();
        List<NXX2_CustomerActivityComments__mdt> listOfCustomerActivityComments = [Select Type__c,Comments__c from NXX2_CustomerActivityComments__mdt];
        if(listOfCustomerActivityComments.size()>0){
            for(NXX2_CustomerActivityComments__mdt nxx2CustomerActivityComments :listOfCustomerActivityComments){
                mapOfTypeAndComments.put(nxx2CustomerActivityComments.Type__c,nxx2CustomerActivityComments.Comments__c); 
            }
        }
        return mapOfTypeAndComments;
    }
    /**
    * @author       Kamal Sharma
    * @date         2018-08-17
    * @description  getDateFromString : This method will convert datetime string to datetime object
    * @param        String stringDate
    * @return       DateTime
    */
	public static DateTime getDateFromString(String stringDate){ 
        DateTime dateTimeObj = null; 
        if(stringDate != null && stringDate.length() > 0){
        	List<String> parts = stringDate.split(' ');
            if(parts.size() > 3){
                String formmatedDateString  = parts[2] + '-' + MonthMap.get(parts[1]) + '-' + parts[0] + ' ' + parts[3] + ':00';
                dateTimeObj = datetime.valueOf(formmatedDateString);
            }
        }
        return dateTimeObj;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-08-17
    * @description  getDateFromString : This method will convert datetime string to datetime object
    * @param        String stringDate
    * @return       DateTime
    */
	public static String formatDateForEmail(Datetime rawDate){ 
        String formattedDate;
        if(rawDate != null){
            Integer day = rawDate.day();
            Integer month = rawDate.month();
            Integer year = rawDate.year();
            if(day == 1 || day == 21){
                formattedDate = day + 'st ';
            }else if(day == 2 || day == 22){
                formattedDate = day + 'nd ';
            }else if(day == 3 || day == 23){
                formattedDate = day + 'rd ';
            }else{
                formattedDate = day + 'th ';
            }
            formattedDate = formattedDate + fullNameOfMonthMap.get(month) + ' ' + year;
        }
        return formattedDate;
    }
}