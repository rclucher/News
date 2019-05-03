/**
* @author       louis.wang@bluewolf.com
* @date         2016-01-27
* @description  This class contains methods for EmailMessage Trigger
* 2016-03-22  Darshan G   Updated
* 2016-04-05  Darshan G   Updated
*/
public with sharing class EmailMessageTrigger_Helper 
{
    public static double maxNumberOfFutureCallsPerTrigger = 10;
    public static Integer numberOfKeywordPerIteration = 10;

    /**
    * @author       Existing code
    * @date         2016-01-27
    * @description  This method is created based on existing code in EmailMessageManagement trigger (before refactoring)
    *                   - Before Insert event
    * @param        List<EmailMessage> - trigger.new
    * @return       n/a
    */
    public static void parseHtmlContent(List<EmailMessage> newObjectList)
    {               
        /**
        * SFE-445 - Parse HTML content (convert to text) for Ad Proof email messages
        * Added LMancilla
        * August 25 2014
        **/ 
        AdProof_Email_Template_Manager aetm = new AdProof_Email_Template_Manager();
        aetm.evaluateEmailMessages(newObjectList);  
    }

    /**
    * @author       Existing code
    * @date         2016-01-27
    * @description  This method is created based on existing code in EmailMessageManagement trigger (before refactoring)
    *                   - After Insert event
    * @param        List<EmailMessage> - trigger.new
    * @param        Map<String, String> - primary_by_Alias_Map
    * @return       n/a
    */
    public static void updateCases(List<EmailMessage> newObjectList, Map<String, String> primary_By_Alias_Map)
    {
        Map<Id, List<EmailMessage>> incomingEmailsByParentId = new Map<Id, List<EmailMessage>>();

        // added by Tim Fabros 26 / 05 / 2014 - SFE-310
        // 
        // This section gets the profile names listed in the custom setting, Outbound_Email_Validation__c,
        // and gathers all the Ids. The Ids are used to determine which profile will be prevented from
        // allowing users to use their own email as the 'Sender' when sending emails.
        //
        // BEGIN: SFE-310
        Map<String, Outbound_Email_Profiles__c> profiles = Outbound_Email_Profiles__c.getAll();
        List<String> profileNames = new List<String>();
        profileNames.addAll(profiles.keySet());

        List<Profile> profileList = [SELECT Name FROM Profile WHERE Name IN: profileNames];
        Set<String> profileSet = new Set<String>();


        try{
           maxNumberOfFutureCallsPerTrigger = Double.valueOf(SystemParameters__c.getValues('Max Number of Future Calls per Trigger').Value__c);
        }catch(Exception ex)
        {
            Exlog.log(ex, 'config', new SystemParameters__c(), 'Geeting Custom setting for Max Number of Future Calls per Trigger');
        }

        for (Profile profile : profileList) 
        {
            profileSet.add(profile.Id);
        }
        // END: SFE-310

        for(EmailMessage em : newObjectList)
        {
            // we only consider incoming emails
            if(em.Incoming)
            {
                if(!incomingEmailsByParentId.containsKey(em.ParentId))
                {
                    incomingEmailsByParentId.put(em.ParentId, new List<EmailMessage>());
                }
                
                incomingEmailsByParentId.get(em.ParentId).add(em);
                
                /**** Updated by Bohao Chen on 25/03/2014 for JIRA issue SFE-308 ****/
                system.debug('@EmailMessageManagement email case: ' + em.ParentId);
                /**** Updated By Bohao Chen *****/
            }

            // added by Tim Fabros 21 / 05 / 2014 - SFE-310
            // 
            // Validation that relies on profileSet gathered from the Outbound_Email_Validation__c custom
            // setting.
            //
            // BEGIN: SFE-310
            else if (!em.Incoming && profileSet.contains(UserInfo.getProfileId())) 
            {
                System.debug('@EmailMessageManagement UserInfo.getUserEmail(): ' + UserInfo.getUserEmail());
                System.debug('@EmailMessageManagement em.FromAddress: ' + em.FromAddress);
                if (UserInfo.getUserEmail() == em.FromAddress)
                    em.addError('You cannot select your personal email');
            }
            // END: SFE-310
        }
        
        system.debug('@EmailMessageManagement incomingEmailsByParentId: ' + incomingEmailsByParentId);
        // Item-00056 2016-04-05 darshan.gosar@bluewolfgroup.com 
            // Added getKeywordMapping method to generate map of keyword mapping 
        

        if(incomingEmailsByParentId.size() > 0)
        {
            List<Case> updatedCases = new List<Case>();
            Set<String> suppliedToEmails = new Set<String>();
        
            /**** Updated by Bohao Chen on 15/04/2014 ***/
            Set<Id> checkedIncomingEmailIds = new Set<Id>();
            /**** Updated By Bohao Chen *****/

            // update case origin
            /**** Updated by Bohao Chen on 25/03/2014 for JIRA issue SFE-308 ****/
            // Item-00062 2016-03-22 darshan.gosar@bluewolfgroup.com 
                // Added Apex_Count_Incoming_Emails__c field in below Case query to resolve issue specific to Item-00062 
            List<id> emailMessagesIdList = new List<id>();
            Integer messagesPerFutureCall = Math.ceil(incomingEmailsByParentId.size()/maxNumberOfFutureCallsPerTrigger).intValue();
            for(Case c : [Select c.Origin, c.Case_Origin_Copy__c, c.SuppliedTo__c, 
                          c.CreatedDate, c.OwnerId, c.IsClosed, c.Status, c.has_Inbound_Email__c,
                          c.Subject, c.Description, c.RecordType.Name, c.Apex_Count_Incoming_Emails__c
                        From Case c 
                        Where c.Id IN: incomingEmailsByParentId.keySet()])
            {
                /**** Updated By Bohao Chen *****/

                // if case has incoming emails and case origin copy is 'Email - Inbound for Routing'
                // update case origin to case origin copy 
                if(incomingEmailsByParentId.containsKey(c.Id))
                {
                    /**** Updated by Bohao Chen on 25/03/2014 for JIRA issue SFE-308 ****/
                    // set flag so that case trigger only update case owner when there is an inbound email
                    c.has_Inbound_Email__c = true;
                    
                    
                    /**** Updated by Bohao Chen on 15/04/2014 ***/                
                    // From field update: ToAddress + IF(ISBLANK(CcAddress), "", ";" + CcAddress) + IF(ISBLANK(BccAddress), "", ";" + BccAddress)
                    // Update reason: 
                    // The following block of code is to mimic two field updates in the config.
                    // The reason why we need apex code for them is because flag "has inbound email" needs to be set 
                    // along with "supplied to email". Then, when case trigger kicks off, we have latest value for "supplied to email" 
                    // and trigger is able to update case owner based on latest value in "supplied to email".
                    // The problem of using workflow to fire field update is that they are always executed after trigger.
                    // By the time workflow kicks off, "has inbound email" has already been set to false and hence, there is no way to change case owner.
                    if(incomingEmailsByParentId.containsKey(c.Id))
                    {
                        for(EmailMessage incomingEmail : incomingEmailsByParentId.get(c.Id))
                        {
                            // 2015-11-16 SFE-688 louis.wang@bluewolf.com
                            //  Only display Primary address on Case record, even if it is coming in as Alias
                            c.SuppliedTo__c = Case_Helper.replace_Alias_with_Primary(incomingEmail.ToAddress, primary_By_Alias_Map);
                            
                            if(String.isNotBlank(incomingEmail.CcAddress))
                            {
                                /**** Updated by Bohao Chen on 29/04/2014 for Jira issue SFE-304, 317 and 322***/
                                // 2015-11-16 SFE-688 louis.wang@bluewolf.com
                                //  Only display Primary address on Case record, even if it is coming in as Alias
                                c.CC_Recipients__c = Case_Helper.replace_Alias_with_Primary(incomingEmail.CcAddress, primary_By_Alias_Map);
                                /**** Update Ends *****/
                            }
                            
                            /*if(String.isNotBlank(incomingEmail.BccAddress))
                            {
                                c.SuppliedTo__c += ';' + incomingEmail.BccAddress;
                            }*/
                            
                            if(!checkedIncomingEmailIds.contains(incomingEmail.Id))
                            {
                                checkedIncomingEmailIds.add(incomingEmail.Id);
                                
                                if(c.Apex_Count_Incoming_Emails__c == null)
                                    c.Apex_Count_Incoming_Emails__c = 1;
                                else
                                    c.Apex_Count_Incoming_Emails__c++;
                            }
                            
                            // added by Tim Fabros 21 / 05 / 2014 - SFE-432
                            // BEGIN:
                            if (c.RecordType.Name == 'NFSS' || c.RecordType.Name == 'Advertising' || c.RecordType.Name == 'Historical Activity') {
                                c.Subject = incomingEmail.Subject;
                                c.Description = incomingEmail.TextBody;
                            }
                            // END:
                            
                            // Item-00056 2016-04-05 darshan.gosar@bluewolfgroup.com 
                                // Calling populateCaseFields method to populate Pillar & Publication field values on Case
                            //c = populateCaseFields(incomingEmail, c, keyWordMapping, compiledKeywordPattern);                            
                            if(emailMessagesIdList.size()<messagesPerFutureCall)
                            {
                                emailMessagesIdList.add(incomingEmail.id);
                            }
                            else if(emailMessagesIdList.size()==messagesPerFutureCall)
                            {
                                try
                                {
                                    futurePopulateCaseFields(emailMessagesIdList);
                                }
                                catch(Exception ex)
                                {
                                    ExLog.log(ex, 'config', new List<sObject>(), 'From EmailMessageTrigger_Helper.futurePopulateCaseFields(). \n' + emailMessagesIdList);
                                }                                
                                
                                emailMessagesIdList = new List<id>();
                                emailMessagesIdList.add(incomingEmail.id);   
                            }

                        }
                    }

                    /**** Updated By Bohao Chen *****/
                    
                    // re-open the case if case has incoming or outgoing emails
                    // and case was closed previously
                    system.debug('@EmailMessageManagement c.IsClosed: ' + c.IsClosed);
        
                    if(c.IsClosed)
                    {
                        c.Status = 'Re-Opened';
                    }                    
                    
                    /**** Updated by Bohao Chen on 25/03/2014 for JIRA issue SFE-308 ****/
                    updatedCases.add(c);
                    /**** Updated By Bohao Chen *****/
                }
            }            
            system.debug('@EmailMessageManagement updatedCases: ' + updatedCases);
                    

            if(emailMessagesIdList.size()>0)
            {
                try
                {
                    futurePopulateCaseFields(emailMessagesIdList);
                }
                catch(Exception ex)
                {
                    ExLog.log(ex, 'config', new List<sObject>(), 'From EmailMessageTrigger_Helper.futurePopulateCaseFields(). \n' + emailMessagesIdList);
                }
            }

            try
            {    
                update updatedCases;
            }
            catch(Exception ex)
            {
                // 2016-01-27 louis.wang@bluewolf.com - Added RELM to track exception
                ExLog.log(ex, 'config', updatedCases, 'From EmailMessageTrigger_Helper.updateCases().');                            
            }
        }

    }

    /**
    * @author       louis.wang@bluewolf.com
    * @date         2016-01-27
    * @description  SFE-830 - This method is created as part of refactoring. 
    *                       - This method generates the primary_by_alias_Map, to be used to replace alias email to primary email.
    * @param        List<EmailMessage> - trigger.new
    * @return       Map<String, String> - primary_by_Alias_Map
    */
    public static Map<String, String> fetch_Primary_By_Alias_Map(List<EmailMessage> newObjectList)
    {   
        Map<String, String> output = new Map<String, String>();
        if(newObjectList!=null)
        {
            List<String> all_EmailAddresses_in_EmailMessages = new List<String>();
            for(EmailMessage em : newObjectList)
            {
                // we only consider incoming emails
                if(em.Incoming)
                {
                    // add all the email addresses in each EmailMessage's ToAddress into a big list
                    if(em.ToAddress!=null)
                    {
                        all_EmailAddresses_in_EmailMessages.addAll(Case_Helper.getEmailList(em.ToAddress));
                    }
                    if(em.CcAddress!=null)
                    {                        
                        all_EmailAddresses_in_EmailMessages.addAll(Case_Helper.getEmailList(em.CcAddress));
                    }
                }
            }
            output = Case_Helper.generate_Primary_By_Alias_Map(all_EmailAddresses_in_EmailMessages);
        }
        return output;
    }

    /**
    * @author       louis.wang@bluewolf.com
    * @date         2016-01-27
    * @description  SFE-830 - This method is updates both ToAddress and CcAddress on EmailMessage, 
    *                           so alias email is replaced with primary email.
    *                       - Before Insert event
    * @param        List<EmailMessage> - trigger.new
    * @return       Map<String, String> - primary_by_Alias_Map
    */
    public static void updateEmailMessages(List<EmailMessage> newObjectList, Map<String, String> primary_By_Alias_Map)
    {
        for(EmailMessage em : newObjectList)
        {
            // we only consider incoming emails
            if(em.Incoming)
            {
                if(em.ToAddress!=null)
                {
                    //  Only display Primary address on EmailMessage record, even if it is coming in as Alias
                    em.ToAddress = Case_Helper.replace_Alias_with_Primary(em.ToAddress, primary_By_Alias_Map);
                }
                if(em.CcAddress!=null)
                {                        
                    //  Only display Primary address on EmailMessage record, even if it is coming in as Alias
                    em.CcAddress = Case_Helper.replace_Alias_with_Primary(em.CcAddress, primary_By_Alias_Map);                    
                }
            }
        }       
    }

    /**
    * @author       darshan.gosar@bluewolf.com
    * @date         2016-04-05
    * @description  Item-00056 - This method generates map of keyword matching settings related to Input object as EmailMessage & Output object as Case
    *
    *               MOD: 2016-04-12 Item-00072 louis.wang@bluewolf.com - Updated so it return List rather than Map. Use SOQL to fetch custom setting, so can perform ordering
    * @param        none
    * @return       Map<String, String> output
    */
    public static Map<String, String> getKeywordMapping()
    {
         Map<String, String> output = new  Map<String, String>(); 
        For( Keyword_Match__c kwm : [SELECT Id,
                                            Input_Keyword__c, 
                                            Output_Object_Field_String__c 
                                        FROM Keyword_Match__c
                                        WHERE Input_Object__c = 'EmailMessage'
                                        AND Output_Object__c = 'Case'
                                        AND Output_Object_Field__c = 'Pillar__c'
                                        ORDER BY External_Id__c ASC])
       {
            output.put(kwm.Input_Keyword__c.toLowerCase(), kwm.Output_Object_Field_String__c);
       }                                            

     return output;
    }
    
    /**
    * @author       celso.desouza@bluewolf.com
    * @date         2016-05-03
    * @description  Item-00056 - this creates and compile the patern used by the keyword matching    
    * @param        Map<String,String>
    * @return       Pattern patternCompiled
    */
    public static Pattern compilePattern(Map<String,String> keywordMatchList)
    {
        List<String> keywords = new List<String>();
        keywords.addAll(keywordMatchList.KeySet()); 
        String regExStr = '(?i)((\\b' + String.join(keywords,'\\b)|(\\b') + '\\b))';
        Pattern patternCompiled = Pattern.compile(regExStr);

        return patternCompiled;  
    }



    /**
    * @author       darshan.gosar@bluewolf.com
    * @date         2016-04-05
    * @description  Item-00056 - This method populates Pillar & Genesys Publication field of Case based on custom setting Keyword Mapping    
    *                       - After Insert event
    *
    *               MOD: 2016-04-12 Item-00072 louis.wang@bluewolf.com - Updated keyword search to be case insensitive. Removed the concept of searching for Publication keyword.
    *               NOTE: Currently, it is observed that if 200 EmailMessage are processed in trigger, when there are 500 "Keyword Match" records, it is very close to the Salesforce limit. 
    *                       We need to ensure "keyword Match" records are way below 500, in order to avoid EmailMessage not created into Salesforce (ie. when Salesforce limit is reached,
    *                       nothing will be created). Note that CPU time defers between environments and time of the day. From debug log in BWDEV, it states,
    *                       Maximum CPU time: 14743 out of 10000 ******* CLOSE TO LIMIT 
    * @param        EmailMessage, Case, Map<String,String>
    * @return       Case - c
    */

    public static Case populateCaseFields(EmailMessage e, Case c,Map<String,String> keywordMatchList, Pattern patternCompiled)
    {              
        String targetString = e.Subject + ' ' + e.TextBody + ' ' + e.HTMLBody;
        
        //added by item-00096
        Iterator<String> iter = keywordMatchList.keySet().iterator();
        map<String,String> tempKm = new map<String,String>();
        Integer kmCounter = 0;
        MatchPosition mp = null;


        try{
           numberOfKeywordPerIteration = Integer.valueOf(SystemParameters__c.getValues('Number of Keyword per Iteration').Value__c);
        }catch(Exception ex)
        {
            Exlog.log(ex, 'config', new SystemParameters__c(), 'Geeting Custom setting for Number of Keyword per Iteration');
        }

        while(iter.hasNext())
        {
            String cKw = iter.next();
            if(kmCounter == numberOfKeywordPerIteration || !iter.hasNext())
            {
                tempKm.put(cKw, keywordMatchList.get(cKw));
                MatchPosition tmpMp= findMatch(tempKm,targetString);
                if((mp==null) || ((mp!=null && tmpMp!=null) && mp.matchStart > tmpMp.matchStart))
                    mp = tmpMp;
                kmCounter =0;
                tempKm = new map<String,String>();
            }
            else if(kmCounter < numberOfKeywordPerIteration)
            {
                tempKm.put(cKw, keywordMatchList.get(cKw));
                kmCounter++;
            }

        }
        
        If (mp!=null)
        {
            c.Pillar__c = mp.matchString;
        }

        //removed by item-00096
        /*
        Matcher m = patternCompiled.matcher(targetString);
        if(m.find())
        {
            String firstMatch = targetString.substring(m.start(), m.end());
            if(keywordMatchList.containsKey(firstMatch.toLowerCase()))
            {
                c.Pillar__c = keywordMatchList.get(firstMatch.toLowerCase());
            }
        }     
        */        


        return c;    
    }

    //added for item-00096
    public static MatchPosition findMatch(Map<String, String> kmPartial,String targetString){
        MatchPosition tmp;
        Pattern compiledKeywordPattern = compilePattern(kmPartial);
        Matcher m = compiledKeywordPattern.matcher(targetString);
            if(m.find())
            {
                String firstMatch = targetString.substring(m.start(), m.end());
                if(kmPartial.containsKey(firstMatch.toLowerCase()))
                {
                     tmp = new matchPosition(m.start(), m.end(),kmPartial.get(firstMatch.toLowerCase()));
                }
            }     
        
        return tmp;
    }


    @future
    public static void futurePopulateCaseFields(list<id> emailMessagesIdList)
    {

        Map<String, String> keyWordMapping = getKeywordMapping();
        Pattern compiledKeywordPattern = compilePattern(keyWordMapping);

        List<Case> casesToUpdate = new List<Case>();
        for(EmailMessage e : [SELECT  id,
                                    parent.id,
                                    parent.Pillar__c,
                                    subject,
                                    textBody,
                                    HTMLBody
                            FROM    EmailMessage
                            WHERE   Id IN :emailMessagesIdList])
        {
            Case c = populateCaseFields(e, 
                                        new Case(id=e.parent.id, Pillar__c=e.parent.Pillar__c, Ready_for_Routing__c=true),
                                        keyWordMapping,
                                        compiledKeywordPattern);
                casesToUpdate.add(c);
        }

        if(casesToUpdate.size()>0)
        {
            update casesToUpdate;
        }

    }

    //added for item-00096
    public class MatchPosition
    {
        public Integer matchStart {get;private set;}
        public Integer matchEnd {get;private set;}
        public String matchString {private get;set;}
        public matchPosition(integer inMatchStart, integer inMatchEnd, String inMatchString)
        {
            matchStart = inMatchStart;
            matchEnd = inMatchEnd;
            matchString = inMatchString;
        }
    }

    public class CustomException extends Exception {}   

}