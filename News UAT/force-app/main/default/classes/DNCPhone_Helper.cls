/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: this helper class contains all helper methods used by related DNC classes
 * Company: Salesforce.com
 * Date: 23/08/2013
 * History:
 * 23/08/2013   Mathanan Yogaratnam       Created
 * 03/10/2013   Bohao Chen                Updated
 * 15/01/2019   David Scullion            Updated
 ---------------------------------------------------------*/
global without sharing class DNCPhone_Helper 
{
    // campaign status that are EXCLUSIVE during campaign query 
    global static final List<String> CAMPAIGN_STATUS = new String[]{'Completed', 'Cancelled', 'Created in Error', 'Marked for Deletion'};
    
    // get custom setting for DNC
    static final DNC_Settings__c dncSetting = DNC_Settings__c.getAll().get('DNC Defaults');
    
    global static final Integer extractScopeSize = (Integer)dncSetting.Extract_Scope_Size__c;
    global static final Integer deleteScopeSize = (Integer)dncSetting.Delete_Scope_Size__c;
    global static final Integer updateScopeSize = (Integer)dncSetting.Update_Scope_Size__c;
    
    
    // query for phone extraction process
    global static final String extractQuery = 'select Lead.id, Lead.Phone, Lead.MobilePhone,'
                                            + 'Contact.id, Contact.Phone, Contact.MobilePhone, Contact.AssistantPhone, Contact.OtherPhone, Contact.HomePhone' 
                                            + ' from CampaignMember'
                                            + ' WHERE campaign.status NOT IN: CAMPAIGN_STATUS';
    
    // query for DNC register self deletion query                                           
    global static final String deleteQuery = 'Select Id, Name, Qualification_Date__c From DNC_Wash_Register__c';
    
    // query for update Contact / Lead phone DNC status process
    global static final String updateQuery = 'select CampaignMember.Id, Lead.id, Lead.Phone, Lead.MobilePhone,'
                                            + ''
                                            + 'Contact.id, Contact.Phone, Contact.MobilePhone, Contact.AssistantPhone, Contact.OtherPhone, Contact.HomePhone' 
                                            + ' from CampaignMember'
                                            + ' WHERE campaign.status NOT IN: CAMPAIGN_STATUS';
    
    public static Map<String, Schema.SObjectField> contactFieldMap = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap();
    public static Map<String, Schema.SObjectField> leadFieldMap = Schema.getGlobalDescribe().get('Lead').getDescribe().fields.getMap();
    
    public static String contactIdPrefix = Contact.SObjectType.getDescribe().getKeyPrefix();
    public static String leadIdPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();
    
    
    //this function checks if the phone number is null and if not it creates a DNC register object
    // and adds to the DNC list
    public static Map<String, DNC_Wash_Register__c> addPhoneToMap(String phoneNum, Map<String, DNC_Wash_Register__c> dncMap, Boolean isFromCampaign)
    {
        if(phoneNum != null)
        {                                       
            DNC_Wash_Register__c dnc = new DNC_Wash_Register__c();                               
            dnc.Phone_Number__c = phoneNum; 
            dnc.Qualification_Date__c = System.Now();
            dnc.DNC_Status__c = 'Not Checked';

            if(isFromCampaign)
            {
                dnc.From_Campaign_At__c = datetime.now();
            }
            
            dncMap.put(dnc.Phone_Number__c, dnc);
        }
        return dncMap;
    }
    
    public static Decimal calculateDaysDiff(DNC_Wash_Register__c a)
    {
        Decimal daysDiff = 0;
        if(a.Qualification_Date__c != null)
        {
            Decimal milliSeconds = System.Now().getTime() - a.Qualification_Date__c.getTime();
            daysDiff = milliSeconds / (1000 * 60 * 60 * 24);
        }
        
        return daysDiff;
    }
    @AuraEnabled
    webservice static void processCampaignMember(String campaignId) 
    {
        // wash campain member for a specified campaign only
        if(campaignId != null)
        {
            // extract phone numbers and push them to DNC register
            List<CampaignMember> campaignMembers = [select Lead.id, Lead.Phone, Lead.MobilePhone, 
                                                    Contact.id, Contact.Phone, Contact.MobilePhone, Contact.AssistantPhone, 
                                                    Contact.OtherPhone, Contact.HomePhone 
                                                    From CampaignMember
                                                    WHERE campaign.status NOT IN: DNCPhone_Helper.CAMPAIGN_STATUS
                                                    And CampaignId =: campaignId];
                                    
            DNCPhone_Helper.extractPhonesFromCampaignMembers(campaignMembers, true);
            
            // self cleaning for DNC register
            // this is going to be a batch job
            DNCPhoneDelete dncDeleteBatch = new DNCPhoneDelete(DNCPhone_Helper.deleteQuery);
            ID idBatch = Database.executeBatch(dncDeleteBatch);
        }
    }
    
    global static void deleteInvalidPhones(List<DNC_Wash_Register__c> dncWashRegisters)
    {
        List<DNC_Wash_Register__c> deletedDncWashRegisterList = new List<DNC_Wash_Register__c>(); 
        
        for(DNC_Wash_Register__c a : dncWashRegisters)
        {
            Decimal daysDiff = DNCPhone_Helper.calculateDaysDiff(a);
            
            System.debug(Logginglevel.DEBUG, 'Phone : ' + a.Name + ' Age : ' + daysDiff);

            //Get the custom settings window and delete records older than that window
            if (daysDiff > dncSetting.Delete_Window__c)
            {
                deletedDncWashRegisterList.add(a);  
            }
        }
        
        if(deletedDncWashRegisterList.size() > 0)
        {
            try
            {
                delete deletedDncWashRegisterList;
            }catch(Exception e)
            {
                // send failed records' id to running user
                List<String> failedIds = new List<String>();
                
                for(Integer i = 0; i < e.getNumDml(); i++)
                {
                   failedIds.add(e.getDmlId(i));
                }
                
                Global_Helper.notifySysAdminException(failedIds, 'Batch Failure on DNC Register Deletion', UserInfo.getUserEmail());

                // 2016-01-25 louis.wang@bluewolf.com - Added RELM to track exception
                ExLog.log(e, 'config', deletedDncWashRegisterList, 'From DNCPhone_Helper.deleteInvalidPhones().');                
            }
        }
    }
    
    global static void extractPhonesFromCampaignMembers(List<CampaignMember> campaignMembers, Boolean isFromCampaign)
    {
        //Using a Map (as we don't want duplicates) to contain extracted phone numbers
        Map<String, DNC_Wash_Register__c> dncMap = new Map<String, DNC_Wash_Register__c>();

        //insert non-null phone numbers into list    
        for(CampaignMember a : campaignMembers)
        {
            //iterate through each of the phone numbers and add to list of it's not null
            dncMap = DNCPhone_Helper.addPhoneToMap(a.Lead.Phone, dncMap, isFromCampaign);
            dncMap = DNCPhone_Helper.addPhoneToMap(a.Lead.MobilePhone, dncMap, isFromCampaign);
            dncMap = DNCPhone_Helper.addPhoneToMap(a.Contact.Phone, dncMap, isFromCampaign);     
            dncMap = DNCPhone_Helper.addPhoneToMap(a.Contact.MobilePhone, dncMap, isFromCampaign); 
            dncMap = DNCPhone_Helper.addPhoneToMap(a.Contact.AssistantPhone, dncMap, isFromCampaign); 
            dncMap = DNCPhone_Helper.addPhoneToMap(a.Contact.OtherPhone, dncMap, isFromCampaign); 
            dncMap = DNCPhone_Helper.addPhoneToMap(a.Contact.HomePhone, dncMap, isFromCampaign);
        }
        
        System.debug(LoggingLevel.DEBUG, 'DNC Set Size : ' + dncMap.size());

        system.debug('====register records being upsert === ' + dncMap.values());
        
        //upsert records with Name field as Phone Number identifier
        try 
        {
            upsert dncMap.values() Phone_Number__c;
        } catch (DmlException e) 
        {
            // send failed records' id to running user
            List<String> failedIds = new List<String>();
                
            for(Integer i = 0; i < e.getNumDml(); i++)
            {
               failedIds.add(e.getDmlId(i));
            }
                
            Global_Helper.notifySysAdminException(failedIds, 'Batch Failure on DNC Register Extract', UserInfo.getUserEmail());        

            // 2016-01-25 louis.wang@bluewolf.com - Added RELM to track exception
            ExLog.log(e, 'config', dncMap.values(), 'From DNCPhone_Helper.extractPhonesFromCampaignMembers().');            
        } 
    }  
    
    global static void updateWashedPhones(List<CampaignMember> cms)
    {
        //Logic below designed so that goverener limits (hopefully) are not exceeded
        //extract phone numbers (all types) and Id's and load into list
        List<String> phoneNumbers = new List<String>();

        for(CampaignMember a : cms)
        {
            if (a.Lead.Phone !=null)
                phoneNumbers.add((String)a.Lead.Phone);
            if (a.Lead.MobilePhone !=null)
                phoneNumbers.add((String)a.Lead.MobilePhone);
            if (a.Contact.Phone !=null)
                phoneNumbers.add((String)a.Contact.Phone);
            if (a.Contact.MobilePhone !=null)
                phoneNumbers.add((String)a.Contact.MobilePhone);
            if (a.Contact.OtherPhone !=null)
                phoneNumbers.add((String)a.Contact.OtherPhone);
            if (a.Contact.AssistantPhone !=null)
                phoneNumbers.add((String)a.Contact.AssistantPhone);
            if (a.Contact.HomePhone !=null)
                phoneNumbers.add((String)a.Contact.HomePhone);

        }

        System.debug(Logginglevel.DEBUG, 'phoneNumbers Size: ' + phoneNumbers.size());

        //if there are no phone numbers found then there's no need to do anything
        if (phoneNumbers.size() == 0)
            return;

        //SOQL select on DNC object 'status' and 'checked date' from dnc register object for each of the phone numbers
        // in phone list and load into another list
        List<DNC_Wash_Register__c> DNCcheckedNumbers = [SELECT Phone_Number__c, DNC_Status__c, Status_Date__c, Phone_Number_In_DNC__c       
                                                        FROM DNC_Wash_Register__c
                                                        WHERE Phone_Number__c in :phoneNumbers
                                                        AND DNC_Status__c != 'Not Checked'
                                                        AND DNC_Status__c != null
                                                        AND DNC_Status__c != 'I'];

        //if there are no matching DNC phone numbers found then there's no need to do anything
        System.debug(Logginglevel.DEBUG, 'DNC select result Size: ' + DNCcheckedNumbers.size());
        
        if (DNCcheckedNumbers.size() == 0)
            return;

        //Create a map with DNC objects to facilitate faster lookup
        Map<String, DNC_Wash_Register__c> DNCcheckedNumbersMap = new Map<String, DNC_Wash_Register__c>();

        for (DNC_Wash_Register__c dnc: DNCcheckedNumbers)
        {
            DNCcheckedNumbersMap.put(dnc.Phone_Number__c, dnc);                 
        }

        //where a match is found for each of the phone numbers in the scope list, create lead or contact
        //object and add to a map (created as map so that duplicates can be checked on key)
        Map<Id, sObject> updateSobjectsMap = new Map<Id, sObject>();

        for(CampaignMember a : cms)
        {
            if (a.Lead.Id != null)
            {
                addSobjectToList(a, 'Phone', 'Phone_DNC_Washed_Date__c', 'Phone_on_DNC__c', updateSobjectsMap, DNCcheckedNumbersMap);
                addSobjectToList(a, 'MobilePhone', 'Mobile_DNC_Washed_Date__c', 'Mobile_on_DNC__c', updateSobjectsMap, DNCcheckedNumbersMap);
            }

            if (a.Contact.Id != null)
            {
                addSobjectToList(a, 'Phone', 'Phone_DNC_Washed_Date__c', 'Phone_on_DNC__c', updateSobjectsMap, DNCcheckedNumbersMap);
                addSobjectToList(a, 'MobilePhone', 'Mobile_DNC_Washed_Date__c', 'Mobile_on_DNC__c', updateSobjectsMap, DNCcheckedNumbersMap);
                addSobjectToList(a, 'OtherPhone', 'Other_Phone_DNC_Washed_Date__c', 'Other_Phone_on_DNC__c', updateSobjectsMap, DNCcheckedNumbersMap);
                addSobjectToList(a, 'AssistantPhone', 'AssistantPhone_DNC_Washed_Date__c', 'AssistantPhone_on_DNC__c', updateSobjectsMap, DNCcheckedNumbersMap);
                addSobjectToList(a, 'HomePhone', 'Home_Phone_DNC_Washed_Date__c', 'Home_Phone_on_DNC__c', updateSobjectsMap, DNCcheckedNumbersMap);
            }
        }

        system.debug('===updateSobjectsMap=== ' + updateSobjectsMap.values());

        //Update contact and Lead list
        if (updateSobjectsMap.size() >0)
        {
            // SFE-828 2016-01-22 louis.wang@bluewolf.com - make update to be in partial save mode (rather than all-or-nothing mode)
            List<sObject> toUpdate = sortSobjectListByPrefix(updateSobjectsMap.values());
            List<Database.SaveResult> srList = Database.update(toUpdate, false);

            Integer i = 0;
            String dmlErrorString = '';
            List<String> failedIds = new List<String>();
            for(Database.SaveResult sr : srList)
            {
                // loop through records that were not saved successfully
                if(!sr.isSuccess())
                {
                    // fetch the first error
                    Database.Error error = sr.getErrors().get(0);
                    String failedDmlMsg = error.getMessage();
                    String failedId = toUpdate.get(i).Id;
                    dmlErrorString += '[' + failedId + ' - ' + failedDmlMsg + ']\n';
                    failedIds.add(failedId);
                }
                i++;
            }
            
            // only display the first 32500 characters, as Additional_Info__c is a long text area field. 
            // With 200 records been processed in one transaction in batch mode, it should be able to capture all the errors most of the time
            if(dmlErrorString.length() > 32500)
            {
                dmlErrorString = dmlErrorString.left(32500);
            }

            if(!failedIds.isEmpty())
            {
                // if there is Dml error, then display it in the Reusable Exception Logging module
                ExLog.log(new CustomException('DNC Update Error - see Additional Info'), 'config', (sObject) null, dmlErrorString);

                // email the error to the user who initiates the "Update Lead/Contact numbers" on Campaign. This is the existing functionality.
                Global_Helper.notifySysAdminException(failedIds, 'Batch Failure on phone DNC Update', UserInfo.getUserEmail());
            }
        }
    }

    private static List<sObject> sortSobjectListByPrefix(List<sObject> unsortSobjectList)
    {
        Map<String, List<sObject>> sObjectsByPrefix = new Map<String, List<sObject>>();
        
        List<sObject> sObjectList = new List<sObject>();
        
        for(sObject s : unsortSobjectList)
        {
            String prefix = String.valueOf(s.Id).subString(0,3);
            
            if(!sObjectsByPrefix.containsKey(prefix))
            {
                sObjectsByPrefix.put(prefix, new List<sObject>());
            }
            
            sObjectsByPrefix.get(prefix).add(s);
        }
        
        for(String prefix : sObjectsByPrefix.keySet())
        {
            sObjectList.addAll(sObjectsByPrefix.get(prefix));
        }
        
        return sObjectList;
    }
    // this function checks if the contact phone fied exists in DNC. If so, the lead record is added to the list for update.
    // it also checks if the lead phone fied exists in DNC. If so, the lead record is added to the list for update.
    private static void addSobjectToList(CampaignMember cm, String phoneField, String phoneDateField, String phoneStatusField, 
                                    Map<Id, sObject> updateSobjectsMap, Map<String, DNC_Wash_Register__c> DNCcheckedNumbersMap)
    {
        system.debug('===updateSobjectsMap before === ' + updateSobjectsMap);
        
        String phoneNumber;
        Contact cnt;
        Lead ld;
        
        system.debug('===phoneField=== ' + phoneField);
        system.debug('=== contact === ' + contactFieldMap);
        system.debug('=== lead === ' + leadFieldMap);
        
        String phoneFieldLower = phoneField.toLowerCase();
        
        system.debug('===phoneField.toLowerCase()=== ' + phoneFieldLower);
        
        if (contactFieldMap.containsKey(phoneFieldLower) && cm.Contact != null && cm.Contact.get(phoneField) != null)
        {
            cnt = cm.Contact;
            phoneNumber = (String)cm.Contact.get(phoneField);
        }
        
        if(leadFieldMap.containsKey(phoneFieldLower) && cm.Lead != null && cm.Lead.get(phoneField) != null)
        {
            ld = cm.Lead;
            phoneNumber = (String)cm.Lead.get(phoneField);
        }

        system.debug('====cnt=== ' + cnt);
        system.debug('====ld=== ' + ld);
        system.debug('====phoneNumber=== ' + phoneNumber);
        
        
        DNC_Wash_Register__c dnc = DNCcheckedNumbersMap.get(phoneNumber);
        
        if (dnc != null)
        {
            sObject sbj;
            
            if(cnt != null)
            {
                sbj = (sObject)cnt;
            }
            else if(ld != null)
            {
                sbj = (sObject)ld;
            }
            
            sbj.put(phoneDateField, dnc.Status_Date__c);
            sbj.put(phoneStatusField, dnc.Phone_Number_In_DNC__c);
            
            updateSobjectsMap.put(sbj.Id, sbj);
        }
            
        system.debug('===updateSobjectsMap after=== ' + updateSobjectsMap);
    }

    //////////////////////////////////////////////////////////////
    // Inner Classes
    //////////////////////////////////////////////////////////////    
    /**    
    * @description  This inner class extends Exception class. It is used by updateWashedPhones to enter Reusable Exception Logging Module.
    * @author       louis.wang@bluewolf.com
    * @date         2016-01-22
    */
    public class CustomException extends Exception {}

}