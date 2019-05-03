/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: 
 * Requirement R-0221: This is the controller for visualforce BookingQuoteConfirmation which used in 
                       Case Publisher Action "Booking Quote / Confirmation"
 * 
 * History:
 * 10/10/2013  Bohao Chen  Created
 * 21/02/2014  Jack        Updated
 ---------------------------------------------------------*/
public with sharing class BookingQuoteConfirmationVF_Ext 
{
    private static final String CONTACT_HAS_NO_EMAIL_MSG = 'The Placer Contact for the booking you have selected to send, does not have an email address. You will be unable to proceed until you update the Contact record with their email address. Please close Quote/Confirmation tab and update the Contact Record.'; 
    
    public Boolean hasBookings {get; set;}
    public Case caseRec {get; set;}
    public Booking__c booking {get; set;}
    public String bookingId {get; set;}
    public String caseAccountId;
    public string filterFromEmail{get;set;}
    public String refTabId {get;set;}

    public List<SelectOption> bookingOptions {get; set;}
    public List<SelectOption> fromEmailAddressOptions {get; set;}
    public Map<Id, Booking__c> bookingById {get; set;}
    public List<publicationWrapper> publications {get; set;}
    
    /**** Updated By Bohao Chen on 03/03/2014 JIRA case: SFE-26****/
    public Set<String> userDivisions 
    { 
        get{ 
                
                if(userDivisions == null)
                {
                        userDivisions = UserSettings_Helper.findUserDivisions(UserInfo.getUserId());
                }
                
                return userDivisions; 
                } 
                private set; 
        }
    /**** Updated By Bohao Chen on 03/03/2014****/
    
    private ApexPages.StandardController ctr;
    
    //private Map<Id, List<String>> publicationCodesByBookingId;
    public Map<Id, List<String>> publicationCodesByBookingId {get; set;}
    public Map<Id, List<String>> publicationNamesByBookingId {get; set;}
    public Map<String, List<String>> classificationsByBookingId {get; set;}
    
    public final String deadlineHtmlString = + '<br /><div style="color: red">Please quote this reference number when calling to confirm or make any alterations/corrections.</div><br />'
                                            + '<br /><b>DEADLINE:</b> ' 
                                            + '<ul>'
                                            + '<li><u>By Email/Fax: </u><b>&lt;deadline date&gt; &lt;deadline time&gt;</b></li>'
                                            + '<li><u>By Phone: </u><b>&lt;deadline date&gt; &lt;deadline time&gt;</b></li>' 
                                            + '</ul>'   
                                            + '<br /><b>Additional Message:</b> &lt;Free Text&gt;<br />'   
                                            + '<br /><b>ADVERTISING DETAILS:</b>';
    

    private String fromEmail;
    public String getFromEmail()
    {
        if(fromEmail==null)
            try 
            {
                fromEmail = SystemParameters__c.getAll().get('Quote_Confirmation_From_Email').value__c;
            }
            catch(Exception ex)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Custom setting Quote_Confirmation_From_Email in System Parameter not found'));
            }
        return fromEmail;
    }


    public BookingQuoteConfirmationVF_Ext(ApexPages.StandardController controller) 
    {
        this.caseRec = (Case)controller.getRecord();
        this.ctr = controller;
        this.bookingOptions = new List<SelectOption>();
        this.hasBookings = false;
        this.fromEmailAddressOptions = new List<SelectOption>();
        this.bookingById = new Map<Id, Booking__c>();
        this.publications = new List<publicationWrapper>();
        
        this.publicationCodesByBookingId = new Map<Id, List<String>>();
        this.classificationsByBookingId = new Map<String, List<String>>();
        this.publicationNamesByBookingId = new Map<Id, List<String>>();
        
        try
        {
            Case c = [Select AccountId From Case Where Id =: caseRec.Id Limit 1];
            
            if(c.AccountId != null)
            {
                this.caseAccountId = c.AccountId;
            }
            else
            {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'This case does not have account'));
            }
            
            /**** Updated By Bohao Chen on 03/03/2014 JIRA case: SFE-26****/
            this.getBookingOptions(userDivisions);
            /**** Updated By Bohao Chen on 03/03/2014 ****/
            
            this.getFromEmailAddressOptions();
            this.changeBooking();
            //Jack added on 24th Feb 2014 to change how "Resend" button is displayed on page
            this.showHideResendButton();
            //*****
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
    
        if(ApexPages.currentPage().getParameters().get('refTabId')!=null)       
            refTabId = ApexPages.currentPage().getParameters().get('refTabId');
    }
    
    /**** Updated By Bohao Chen on 03/03/2014 JIRA case: SFE-26****/
    private void getBookingOptions(Set<String> userDivisions)
    /**** Updated By Bohao Chen on 03/03/2014 ****/
    {
        // reset collections
        this.bookingOptions.clear();
        this.bookingById.clear();
        
        // these two sets just to detect duplicates
        Map<Id, Set<String>> publicationCodeSetByBookingId = new Map<Id, Set<String>>();
        Map<Id, Set<String>> classificationSetByBookingId = new Map<Id, Set<String>>();
        
        // To get UNIQUE publications and classifications from booking line items
        this.publicationCodesByBookingId.clear();
        this.classificationsByBookingId.clear();
        this.publicationNamesByBookingId.clear();
        
        // this variable is used later when we need to find publication name via soql query
        Set<String> publicationCodes = new Set<String>();
            
        /**** Updated by Bohao Chen on 03/03/2014 JIRA case: SFE-26 ****/
        // 1. Only display CyberAd bookings modified against the Account that is linked to the case within the last 7 days ordered by modified date
        // 2. Limit of 20 records to be displayed 
        // 3. Bookings displayed to a user should be specific to their CyberAd instances only
        // 4. Users should see their division bookings in their booking list
        if(userDivisions.size() > 0)
        {
              
                                    
                             for(Booking__c b : [Select Id, Name, Quote_Confirmation__c, AdProof_Required__c, Quote_or_Confirmation_Sent_Date__c, Send_Channel__c, LastModifiedById,   
                                    CyberAd_Division__c, Resend_Pick__c, Quote_or_Confirmation_From_Email__c, Ad_Proof_Document__c, Quote_Confirmation_Fax__c, Modified_By_Copy__c, 
                                    Quote_Confirmation_Message__c, Status__c, Integration_Date__c, LastModifiedDate, Run_Schedule__c, Quote_Confirmation_cc__c,
                                    Quote_Confirmation_bcc__c, Placer_Contact__c, Placer_Contact__r.Name, Placer_Contact__r.Email, Placer_Contact__r.Fax, Fax_Content__c,Apex_Adproof_Previously_Sent__c,
                                    (Select Publication__c, Classification__c From Booking_Lines__r)
                                    From Booking__c 
                                    Where Advertiser_Account__c =: this.caseAccountId
                                  And Source_System__c = 'CyberAd'
                                    And LastModifiedDate = LAST_N_DAYS:7
                                    And CyberAd_Division__c =: userDivisions
                                    order by LastModifiedDate DESC, Name
                                    limit 20])
                /**** Updated by Bohao Chen on 03/03/2014 ****/
                {
        
                    String optionLabel = b.Name + ' | ' + b.CyberAd_Division__c + ' | ' + b.Status__c + ' | Modified Date: ' + b.LastModifiedDate.format();
                        if(b.Run_Schedule__c!=null)
                        {
                            String runSchedule = b.Run_Schedule__c;
                                if(runSchedule.length()>42)
                                {
                                    runSchedule = runSchedule.substring(0,42) + '...';
                                }
                            optionLabel += ' | Run Schedule: ' + runSchedule;
                        }
                    this.bookingOptions.add(new SelectOption(b.Id, optionLabel));
                    this.bookingById.put(b.Id, b);
                    
                    
                    // find unique publication codes from booking line items
                    if(!publicationCodeSetByBookingId.containsKey(b.id))
                    {
                        publicationCodesByBookingId.put(b.id, new List<String>());
                        publicationCodeSetByBookingId.put(b.id, new Set<String>());
                    }
                    
                    // find unique classifications from booking line items
                    if(!classificationSetByBookingId.containsKey(b.id))
                    {
                        classificationsByBookingId.put(b.id, new List<String>());
                        classificationSetByBookingId.put(b.id, new Set<String>());
                    }
                        
                    for(Booking_Line_Item__c bli : b.Booking_Lines__r)
                    {
                        // find unique publication codes from booking line items
                        /*if(!publicationCodeSetByBookingId.containsKey(b.id))
                        {
                            publicationCodesByBookingId.put(b.id, new List<String>());
                            publicationCodeSetByBookingId.put(b.id, new Set<String>());
                        }*/
                        
                        if(!publicationCodeSetByBookingId.get(b.id).contains(bli.Publication__c))
                        {
                            publicationCodesByBookingId.get(b.id).add(bli.Publication__c);
                            publicationCodeSetByBookingId.get(b.id).add(bli.Publication__c);
                        }
        
                        // find unique classifications from booking line items
                        /*if(!classificationSetByBookingId.containsKey(b.id))
                        {
                            classificationsByBookingId.put(b.id, new List<String>());
                            classificationSetByBookingId.put(b.id, new Set<String>());
                        }*/
                        
                        if(!classificationSetByBookingId.get(b.id).contains(bli.Classification__c))
                        {
                            classificationsByBookingId.get(b.id).add(bli.Classification__c);
                            classificationSetByBookingId.get(b.id).add(bli.Classification__c);
                        }
                        
                        publicationCodes.add(bli.Publication__c);
                    }
                    
                    system.debug('@getBookingOptions Quote_Confirmation_Message__c: ' + b.Quote_Confirmation_Message__c);
                }

                this.convertPublicationCodesToNames(publicationCodesByBookingId, publicationCodes);
                
                system.debug('==publicationCodesByBookingId== ' + publicationCodesByBookingId);
                system.debug('==classificationsByBookingId== ' + classificationsByBookingId);
        }
                        
        if(bookingOptions.size() > 0)
        {
            this.hasBookings = true;
            
            // if it is first time we load this page (booking id is null)
            // we use first booking in dropdown list as default booking
            if(this.bookingId == null)
            {
                this.bookingId = bookingOptions[0].getValue(); 
                this.booking = bookingById.get(bookingId);
                //this.booking.AdProof_Required__c = true;
                this.generateQuoteConfirmationMessage(this.booking.Quote_Confirmation_Message__c);         

            }
            else
            {
                this.booking = bookingById.get(bookingId);
            }

            if(this.booking.Send_Channel__c == 'Email' && String.isBlank(this.booking.Placer_Contact__r.Email))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CONTACT_HAS_NO_EMAIL_MSG));
            }
            
            this.findDivisionPublications();
        }
        else
        {
            this.hasBookings = false;
        }
    }

    // this function translate all booking items publication code to publication name
    private void convertPublicationCodesToNames(Map<Id, List<String>> publicationCodesByBookingId, Set<String> publicationCodes)
    {
        Map<String, String> publicationNameByCode = new Map<String, String>();
        
        for(Publication_Product__c pp : [Select p.Publication__c, p.Publication_Code__c
                                        From Publication_Product__c p 
                                        Where p.Publication_Code__c IN: publicationCodes])
        {
            publicationNameByCode.put(pp.Publication_Code__c, pp.Publication__c);
        }
        
        for(String bookingId : publicationCodesByBookingId.keySet())
        {
            if(!this.publicationNamesByBookingId.containsKey(bookingId))
            {
                this.publicationNamesByBookingId.put(bookingId, new List<String>());
            }
                
            for(String publicationCode : publicationCodesByBookingId.get(bookingId))
            {
                if(publicationNameByCode.containsKey(publicationCode))
                {
                    this.publicationNamesByBookingId.get(bookingId).add(publicationNameByCode.get(publicationCode));
                }
            }
        }
    }
    
    private void getFromEmailAddressOptions()
    {
        system.debug('@ getFromEmailAddressOptions()');
        system.debug('@ getFromEmailAddressOptions() filterFromEmail: ' + filterFromEmail);
        
        
        this.fromEmailAddressOptions = new List<SelectOption>();
        list<Group> groups = new list<Group>();
        if(filterFromEmail!=null && filterFromEmail.length()>3)
        {
            string f = '%' + filterFromEmail+ '%';
            groups = [Select Email FROM Group WHERE Type = 'Queue' and Email like :f ORDER BY Email];
        }
        else
            groups = [Select Email FROM Group WHERE Type = 'Queue' and Email != NULL ORDER BY Email];


        system.debug('@ getFromEmailAddressOptions() groups: ' + groups);
        for(Group g : groups)
        {
            this.fromEmailAddressOptions.add(new SelectOption(g.Email, g.Email));
        }
    }
    

    public void doFilterFromEmailAddressOptions()
    {
        getFromEmailAddressOptions();
    }


    //fax or email
    public string selectedMedia {get{return selectedMedia = selectedMedia!=null?selectedMedia:'Email';} set;}
    public void onChnageSelectedMedia()
    {

        system.debug('@onChnageSelectedMedia selectedMedia:'+ selectedMedia);
        //booking.Send_Email__c = true;
        //booking.Send_Fax__c = false;

        //if(selectedMedia=='Fax')
        if(booking.Send_Channel__c == 'Fax')
        {
            //booking.Send_Email__c = false;
            //booking.Send_Fax__c = true;
            if((String.isBlank(booking.Quote_Confirmation_Fax__c))
             && String.isNotBlank(booking.Placer_Contact__r.Fax))
                booking.Quote_Confirmation_Fax__c = booking.Placer_Contact__r.Fax.replace(' ', '').replace('-','');

        }
        
        if(this.booking.Send_Channel__c == 'Email' && String.isBlank(this.booking.Placer_Contact__r.Email))
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CONTACT_HAS_NO_EMAIL_MSG));
        }
    }

    public PageReference save()
    {
        PageReference pr = null;        
        // get adProof document object prefix
        String adProofDocumentPrefix = Schema.getGlobalDescribe().get('Document').getDescribe().getKeyPrefix();
         
        // firstly, check if adProof document exists if adProof is required
        // even Ad_Proof_Document__c field contains value, we still need to check if it is valid document id
        // Note: we should not rely on trigger to throw the error message if adProof document doesn't exist.
        // Moreover, in trigger, we send error message to Quote or Confirmation User via email
    
        try
        {
            booking.Quote_Publications__c = null;
            
            // if it is quote, we have to save selected publications on the page
            // so later we can include these publications in VF email template
            if(booking.Quote_Confirmation__c == 'Quote')
            {
                booking.Quote_Publications__c  = this.covertPublicationsToHtmlString();
            }

            booking.Quote_or_Confirmation_User__c = UserInfo.getUserId();
            

            
            // if quote/confirmation is send via fax, save fax content for this booking by sending a dummy email
            if(booking.Send_Channel__c == 'Fax')
            {
      /*
                id noReplyOrgWideEmailAddress = [Select o.Id From OrgWideEmailAddress o where o.DisplayName ='NoReply'].id;
        
                EmailTemplate et = [Select e.Id From EmailTemplate e Where e.Name = 'Booking Confirmation' limit 1];      
                string faxContent='';
                //Create a dummy outbound emails
                Savepoint sp = Database.setSavepoint();
                //emailMessagesByBooking.put(b.id, BookingManagement_Trigger_Helper.buildEmailMessage(b, noReplyOrgWideEmailAddress, et, false, false));
                Messaging.SingleEmailMessage emailMsg = BookingManagement_Trigger_Helper.buildEmailMessage(booking, noReplyOrgWideEmailAddress, et, false, false);
                Messaging.sendEmail(new Messaging.Email[] { emailMsg });
                
                //booking.Fax_Content__c = emailMsg.getHtmlBody();
                faxContent = emailMsg.getHtmlBody();
                system.debug('?????????faxContent:'+faxContent);
                */
                booking.Modified_By_Copy__c = UserInfo.getUserId();
                booking.Apex_Case_ID__c = caseRec.id;
                //roll back to savepoint so that email is not sent
                //Database.rollback(sp);

                
            }
            
            system.debug('@BookingQuoteConfirmationVF_Ext save');
            
            system.debug('@BookingQuoteConfirmationVF_Ext save booking.LastModifiedById: ' + booking.LastModifiedById);
            system.debug('@BookingQuoteConfirmationVF_Ext save booking.Modified_By_Copy__c: ' + booking.Modified_By_Copy__c);
            
            
            update booking;
            
             id noReplyOrgWideEmailAddress = [Select o.Id From OrgWideEmailAddress o where o.DisplayName ='NoReply'].id;
        
                EmailTemplate et = [Select e.Id From EmailTemplate e Where e.Name = 'Booking Confirmation' limit 1];      
                string faxContent='';
                //Create a dummy outbound emails
                Savepoint sp = Database.setSavepoint();
                //emailMessagesByBooking.put(b.id, BookingManagement_Trigger_Helper.buildEmailMessage(b, noReplyOrgWideEmailAddress, et, false, false));
                Messaging.SingleEmailMessage emailMsg = BookingManagement_Trigger_Helper.buildEmailMessage(booking, noReplyOrgWideEmailAddress, et, false, false);
                Messaging.sendEmail(new Messaging.Email[] { emailMsg });
                
                //booking.Fax_Content__c = emailMsg.getHtmlBody();
                faxContent = emailMsg.getHtmlBody();
                system.debug('?????????faxContent:'+faxContent);
                
                
                //roll back to savepoint so that email is not sent
                Database.rollback(sp);
                
                caseRec.Apex_Fax_Body__c=faxContent;
                update caseRec;
            
            
        }
        catch(DMLException e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getdmlMessage(0)));
            return null;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        } 

        if(refTabId==null)
            pr = new PageReference('/' + caseRec.id);            
    
        /**** Updated By Bohao Chen on 03/03/2014 JIRA case: SFE-26 ****/
        // refresh all bookings to reflect latest changes on bookings
        this.getBookingOptions(userDivisions);
        /**** Updated By Bohao Chen on 03/03/2014 ****/
        
        return pr;
    }
    

    public PageReference cancel()
    {
        PageReference pr = null;
        if(refTabId==null)
            pr = new PageReference('/' + caseRec.id);
        return pr;
    }

    
    private String covertPublicationsToHtmlString()
    {
        String publicationString = '<table style="border-collapse: collapse;">'
                                + '<thead>'
                                + '<tr><th style="border: 1px solid black;text-align: left;">Publication</th></tr>'
                                + '</thead><tbody>';
        
        for(publicationWrapper p : publications)
        {
            if(p.isSelect)
            {
                publicationString += '<tr><td style="border: 1px solid black;text-align: left">' + p.publication + '</td></tr>';
            }
        }
        
        publicationString += '</tbody></table>';
        
        return publicationString;
    }
    
    // choose booking when user pick one of dropdown list values
    public PageReference changeBooking()
    {
        this.booking = bookingById.get(bookingId);
        
        if(this.booking != null)
        {
            //this.booking.AdProof_Required__c = true;
    
            if(this.booking.Send_Channel__c == 'Email' && String.isBlank(this.booking.Placer_Contact__r.Email))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CONTACT_HAS_NO_EMAIL_MSG));
            }
            
            system.debug('@BookingQuoteConfirmationVF_Ext changeBooking bookingId: ' + bookingId);
            system.debug('@BookingQuoteConfirmationVF_Ext changeBooking: ' + this.booking.Quote_Confirmation_Message__c);
    
            /*if(String.isBlank(this.booking.Quote_Confirmation_Message__c) || this.booking.Quote_Confirmation_Message__c == '<br>')
            {
                this.generateQuoteConfirmationMessage();
            }*/
            
            this.generateQuoteConfirmationMessage(this.booking.Quote_Confirmation_Message__c);
            this.findDivisionPublications();
        }
        
        return null;
    }
    
    public PageReference changeFieldValueOnPage()
    {
        this.generateQuoteConfirmationMessage(null);
        return null;
    }
    
    // generate default booking confirmation / quote email message
    private void generateQuoteConfirmationMessage(String originalMsg)
    {
        if(String.isBlank(originalMsg))
        {
            String message = '';
            
            if(this.booking.Quote_Confirmation__c == 'Quote')
            {
                if(this.booking.AdProof_Required__c)
                {
                    message += '<b>Please find attached the proof, if there are any alterations or queries, please contact us before the deadline stated below, as it is advertiser\'s responsibility to ensure the attached proof and ad information details are correct.</b><br />';
                }
                else
                {
                    message += '<b>Please contact us before the deadline with any changes and payment for your ad to publish</b><br />';
                }
                
                message += '<br /><b>Reference #: </b>' + this.booking.Name 
                                    + deadlineHtmlString
                                    + '<br />'
                                    + '<ul>'
                                    + '<li><b>Charged To:</b> Quote Only</li>'
                                    + '<li><b>Classification:</b> &lt;Booking Classification/Section&gt;</li>' 
                                    + '<li><b>Total Cost:</b> &lt;Booking Cost&gt;</li>'
                                    + '<li><b>Publish Date/s:</b> &lt;Booking Run Schedule&gt;</li>'
                                    + '</ul>';
            }
            else if(this.booking.Quote_Confirmation__c == 'Confirmation')
            {
                if(this.booking.AdProof_Required__c)
                {
                    message += '<b>Please find attached the proof of your advertisement. If there are any alterations or queries, please contact us before the deadline stated below, as it is advertiser’s responsibility to ensure the attached proof and ad information details are correct.</b><br />';
                }
                
                message += '<br /><b>Reference #: </b>' + this.booking.Name + deadlineHtmlString;
                                    
            }
            
            this.booking.Quote_Confirmation_Message__c = message;
        }
        else
        {
            this.booking.Quote_Confirmation_Message__c = originalMsg;
        }
    }
    
    // this is only for quote to show a list of publications based on booking division
    // in order for user to choose which publications to be included in the email
    private void findDivisionPublications()
    {
        publications.clear();
        
        if(String.isNotBlank(this.booking.CyberAd_Division__c))
        {
            for(Publication_Product__c pp : [Select p.Publication__c
                                            From Publication_Product__c p 
                                            Where p.Division__c =: this.booking.CyberAd_Division__c
                                            And Show_In_Booking_Confirmation_Pub_Screen__c = true])
            {
                publicationWrapper product = new publicationWrapper(pp.Publication__c, false);
                publications.add(product);
            }
        }
    }
    
    public class publicationWrapper
    {
        public Boolean isSelect {get;set;}
        public String publication {get;set;}
        
        public publicationWrapper(String publication, Boolean isSelect)
        {
            this.isSelect = isSelect;
            this.publication = publication;
        }
    }
    
    public PageReference resetFields()
    {
        system.debug('===this.booking.Resend_Pick__c=== ' + this.booking.Resend_Pick__c);
        
        if(this.booking.Resend_Pick__c == 'Resend Immediately' || this.booking.Resend_Pick__c == 'Resend with Booking Change')
        {
            //this.booking.Send_Email__c = false;
            //this.booking.Send_Fax__c = false;
            this.booking.Quote_or_Confirmation_Sent_Date__c = null;
            
            if(this.booking.Resend_Pick__c == 'Resend with Booking Change')
            {
                this.booking.Integration_Date__c = null;
                this.booking.Ad_Proof_Document__c = null;
            }
            
            this.booking.Resend_Pick__c = null;
            //this.booking.AdProof_Required__c = null;
        }
        
        return null;
    }
    
    public boolean hasPreviouslySentFax{get;private set;}
    public boolean hasPreviouslySentEmail{get;private set;}
    
    
    //look at all tasks created for the given booking and find if there is an email or fax has been sent previously
    private void showHideResendButton(){

        /*** update by Bohao Chen on 03/03/2014 ****/
        /*** reason for update: when booking is null, it will throw error message ***/
        if(this.booking != null)
        {
                for(Task aTask : [Select WhoId, WhatId, Type, Subject, Status, CreatedDate 
                                                        From Task t 
                                                        Where whatid =: this.booking.id 
                                                        And (type='Fax - Outbound' or type ='Email - Outbound') 
                                                        Order by createddate desc])
                {
                    if(aTask.type == 'Email - Outbound'){
                        hasPreviouslySentEmail=true;
                    }
                    
                    if(aTask.type == 'Fax - Outbound'){
                        hasPreviouslySentFax=true;
                    }
        
                }  
        }         
    }
}