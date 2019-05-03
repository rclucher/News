/*---------------------------------------------------------
* Author: Bohao Chen
* Company: Salesforce.com
* Description: 
* 1. To change owner of booking's sales order based on value of sales rep on booking. R-0799
* 2. Send AdProof confirmation/quote for bookings R-0221
* History:
* 28/08/2013  Bohao Chen  Create
* 14/10/2013  Bohao Chen  Update
* 21/02/1014  Jack        Update
* 2016-01-26  Darshan G   Update
* 2016-02-25  Atul Gupta  Updated
* 2016-03-01  Darshan G   Update
* 2018-01-30  Nishank Tandon Update
---------------------------------------------------------*/
public without sharing class BookingManagement_Trigger_Helper
{  
    
    //Method added for Backlog item 1127
    public static String subStringByCharacterLength (String fieldName,Integer trimLength)
    {   
        String truncatedString='';
        if(fieldName!=null && fieldName!='')
        {
          if(fieldName.length()>trimLength)
            {
            truncatedString = (fieldName).substring(0,trimLength);
            }
        else
           {
            truncatedString=fieldName;
           }
        }
        return truncatedString;
    }
    
    public static Map<String, user> getUserIdMap(Set<String> networkUsernames)
    {
        //Map<String, id> userIdMapByUserNetworkUsername = New Map<String, Id>();
		Map<String, user> userIdMapByUserNetworkUsername = New Map<String, user>();
        
        // find users based on network logins
        if(networkUsernames.size() > 0)
        {
            for(User u : [Select u.Network_Username__c,u.UserRole.Name 
                          From User u 
                          Where u.Network_Username__c IN: networkUsernames])
            {
                //userIdMapByUserNetworkUsername.put(u.Network_Username__c.toUpperCase(), u.Id);
				userIdMapByUserNetworkUsername.put(u.Network_Username__c.toUpperCase(), u);
            }
        }
        
        system.debug('====userIdMapByUserNetworkUsername=== ' + userIdMapByUserNetworkUsername);
        return userIdMapByUserNetworkUsername;
    }
    
    // SFE-794 2016-03-01 darshan.gosar@bluewolfgroup.com 
    // Updated method definition to pass map of booking instead of set of id in order to get rid of extra query on bookings    
    // update owner of booking's sales order
    public static void updateSalesOrderOwnerAndAdTaker(Map<Id, Booking__c> validBookingIdMap)
    {
        List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();
        
        for(Sales_Order__c s : [Select s.OwnerId, s.Ad_Taker__c From Sales_Order__c s Where s.Id IN: validBookingIdMap.keySet()])
        {
            s.OwnerId = validBookingIdMap.get(s.Id).Sales_Order_Owner__c;
            s.Ad_Taker__c = validBookingIdMap.get(s.Id).Sales_Order_Ad_Taker__c;
            salesOrders.add(s);
        }
        
        system.debug('====salesOrders2=== ' + salesOrders);
        // 2016-02-25 atul.gupta@bluewolfgroup.com - SFE-824 Exception Log framework method added to catch any exceptions on DML
        try{
            update salesOrders;
        } catch(Exception ex){
            ExLog.log(ex, 'config', salesOrders, 'SFE-824 Update Owner of Booking\'s Sales Order');
        }
        
    }
    
    
    public static Messaging.SingleEmailMessage buildEmailMessage(Booking__c b, Id orgwideEmailAddress,
                                                                 EmailTemplate et,
                                                                 boolean includeCc, boolean includeBcc)
    {
        system.debug('@ BookingManagement_Trigger_Helper buildEmailMessage');          
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        
        List<String> bccList = new List<string>();            
        if(includeBcc && b.Quote_Confirmation_bcc__c!=null && b.Quote_Confirmation_bcc__c.trim().length()>0)
        {
            string bcc = b.Quote_Confirmation_bcc__c.trim().replace(' ','').replace(',',';');
            bccList = bcc.split(';');
            if(bccList.size()>0)
            {
                mail.setBccAddresses(bccList);
            }
        }
        
        List<String> ccList = new List<string>();
        if(includeCc && b.Quote_Confirmation_cc__c!=null && b.Quote_Confirmation_cc__c.trim().length()>0)
        {
            string cc = b.Quote_Confirmation_cc__c.trim().replace(' ','').replace(',',';');
            ccList = cc.split(';');
            if(ccList.size()>0)
            {
                mail.setCcAddresses(ccList);
            }
            
        }
        
        mail.setTemplateId(et.Id);
        mail.setTargetObjectId(b.Placer_Contact__c);
        mail.setWhatId(b.Id);
        mail.setSaveAsActivity(true);
        
        if(orgwideEmailAddress!=null)
        {
            mail.setOrgWideEmailAddressId(orgwideEmailAddress);
        }
        
        if(b.Quote_or_Confirmation_From_Email__c!=null)
        {
            mail.setInReplyTo(b.Quote_or_Confirmation_From_Email__c);
        }
        
        // attach adProof PDF if adProof required field is checked on booking
        if(b.AdProof_Required__c && String.isNotBlank(b.Ad_Proof_Document__c) && b.Ad_Proof_Document__c.trim().length()>=15)
        {
            mail.setDocumentAttachments(new Id[]{b.Ad_Proof_Document__c});
        }
        
        return mail;
        
    }
    
    // send booking confirmation / quote email 
    // requirement: R-0221
    public static void sendBookingQuoteConfirmationEmail(List<Booking__c> bookings)
    {
        system.debug(logginglevel.error, '@ BookingManagement_Trigger_Helper sendBookingQuoteConfirmationEmail');        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        //List<String> documentIds = new List<String>();
        set<Id> emailSentBookingIds = new set<Id>();
        id noReplyOrgWideEmailAddress;
        
        try
        {
            noReplyOrgWideEmailAddress = [Select o.Id From OrgWideEmailAddress o where o.DisplayName ='Adproofs'].id;
        }
        catch(Exception ex)
        {}
        
        EmailTemplate et = [Select e.Id From EmailTemplate e Where e.Name = 'Booking Confirmation' limit 1];
        
        // create emails and ready to send out
        for(Booking__c b : bookings)
        {           
            emails.add(BookingManagement_Trigger_Helper.buildEmailMessage(b, noReplyOrgWideEmailAddress, et, true, true));           
            // get booking ids
            // time stamp Quote or Confirmation Sent Date
            emailSentBookingIds.add(b.Id);
        }
        
        system.debug(logginglevel.error, '@BookingManagement_Trigger_Helper sendBookingQuoteConfirmationEmail emails: ' + emails);
        
        // send email
        if(emails.size() > 0)
        {
            List<Messaging.SendEmailResult> sendEmailResults = new List<Messaging.SendEmailResult>{};
                
                sendEmailResults = Messaging.sendEmail(emails, false);
            
            // try to catch any exception of sendemail function
            for(Messaging.SendEmailResult sendEmailResult: sendEmailResults)
            {
                if(!sendEmailResult.isSuccess())
                {
                    for (Messaging.Sendemailerror sendEmailError : sendEmailResult.getErrors())
                    {
                        String errorBookingId = sendEmailError.getTargetObjectId();
                        
                        if(emailSentBookingIds.contains(errorBookingId))
                        {
                            emailSentBookingIds.remove(errorBookingId);
                        }
                        
                        String subject = 'Sending email failed';
                        String[] toAddresses = new String[]{'bohao.chen@bluewolf.com', 'jimmy.tram@bluewolf.com'};
                            String msg = 'error booking id is: ' + errorBookingId + '. Send Email Result Error: ' + sendEmailError.Message + '<br />'
                            + 'This error may be because'
                            + '1. logo file name in logo folder is different from division name used in external system user credentials; <br />'
                            + '2. division information records has different division name from those used in external system user credentials;';
                        
                        Global_Helper.sendMessageToUsers(subject, msg, toAddresses, 'html');
                    }
                }
            }      
        }
        
        system.debug(logginglevel.error, '@BookingManagement_Trigger_Helper sendBookingQuoteConfirmationEmail emailSentBookingIds: ' + emailSentBookingIds);
        
        // how does sent date flag gets checked
        BookingManagement_Trigger_Helper.updateBookingSendDateFlag(emailSentBookingIds);
    } 
    
    
    public static void sendBookingQuoteConfirmationFax(List<booking__c> bookings)
    {
        
        system.debug('@ BookingManagement_Trigger_Helper sendBookingQuoteConfirmationFax');
        set<Id> bookingIds = new set<Id>();
        set<id> bookingsNotSent = new set<id>();
        Integer counter = 0; 
        
        
        
        for(booking__c booking :bookings)
        {
            counter++;
            system.debug('@ BookingManagement_Trigger_Helper sendBookingQuoteConfirmationFax counter:' + counter );
            Integer numberOfFutureCallsLeft = Limits.getLimitFutureCalls() - Limits.getFutureCalls();
            system.debug('@ BookingManagement_Trigger_Helper sendBookingQuoteConfirmationFax numberOfFutureCallsLeft:' + numberOfFutureCallsLeft );
            
            if(numberOfFutureCallsLeft > 0)
                bookingIds.add(booking.id);
            else
                bookingsNotSent.add(booking.id);
            
            
            if(counter>=10 || counter == numberOfFutureCallsLeft)
            {
                BookingManagement_Trigger_Helper.BookingQuoteConfirmationFaxChunk(bookingIds);
                // how does sent date flag gets checked
                //    BookingManagement_Trigger_Helper.updateBookingSendDateFlag(bookingIds);
                counter = 0;
                bookingIds = new set<id>();
            }
        }
        
        system.debug('@ BookingManagement_Trigger_Helper sendBookingQuoteConfirmationFax bookingsNotSent.size():' + bookingsNotSent.size() );
        
        if(bookingsNotSent.size()>0)
        {
            List<id> bookingsNotSentList = new List<id>();
            bookingsNotSentList.addAll(bookingsNotSent);
            Global_Helper.notifySysAdminException(bookingsNotSentList, 'Quote/Confirmation for faxes could not be sent, see booking Ids', UserInfo.getUserEmail());
        }
        
        system.debug('@ BookingManagement_Trigger_Helper sendBookingQuoteConfirmationFax bookingIds.size():' + bookingIds.size() );
        
        if(bookingIds.size()>0)
        {
            BookingManagement_Trigger_Helper.BookingQuoteConfirmationFaxChunk(bookingIds);
            // how does sent date flag gets checked
            //    BookingManagement_Trigger_Helper.updateBookingSendDateFlag(bookingIds);
        }
    }
    
    
    @future(callout=true)
    public static void BookingQuoteConfirmationFaxChunk(set<Id> bookingIds)
    {
        system.debug('@ BookingManagement_Trigger_Helper BookingQuoteConfirmationFaxChunk');              
        BookingManagement_Trigger_Helper.sendBookingQuoteConfirmationFaxChunk(bookingIds);
    }
    
    //Should only be called from a future call
    private static void sendBookingQuoteConfirmationFaxChunk(set<Id> bookingIds)
    {
        system.debug('@ BookingManagement_Trigger_Helper sendBookingQuoteConfirmationFaxChunk');        
        List<Booking__c> bookings = [Select Id, Name, Quote_Confirmation__c, AdProof_Required__c, Quote_or_Confirmation_Sent_Date__c, Fax_Content__c, Modified_By_Copy__c,  
                                     CyberAd_Division__c, Resend_Pick__c, Quote_or_Confirmation_From_Email__c, Ad_Proof_Document__c, Quote_Confirmation_Fax__c,
                                     Quote_Confirmation_Message__c, Status__c, Integration_Date__c, LastModifiedDate, Run_Schedule__c, Quote_Confirmation_cc__c,
                                     Quote_Confirmation_bcc__c, Placer_Contact__c, Placer_Contact__r.id, Placer_Contact__r.Name, Placer_Contact__r.Email, Placer_Contact__r.Fax,Apex_Case_ID__c
                                     From Booking__c 
                                     Where id IN :bookingIds];
        
        
        List<id> bookingsNotSent = new List<id>();
        set<id> documentIds = new set<id>();
        for(booking__c b : bookings)
        {
            if(b.Ad_Proof_Document__c!=null)
            {
                documentIds.add(b.Ad_Proof_Document__c);
            }
        }
        
        map<id, document> documents = new map<id, document>([select name, body, type, ContentType, BodyLength from document where id IN :documentIds]);
        
        List<MyFax_Helper> myFaxes = new List<MyFax_Helper>();
        set<id> faxSent = new set<id>();
        /*
Jack added on 21/02/2014 to fix the issue of incorrect fax content.
*/
        map<id,id> bookingIDCaseID = new map<id,id>();
        for(Booking__c b : bookings)
        { 
            bookingIDCaseID.put(b.id,b.Apex_Case_ID__c);
            
        }
        
        Map<id,Case> cases = New Map<id, Case>();
        
        for(Case aCase:[select id, Apex_Fax_Body__c from Case where id in: bookingIDCaseID.values()]){
            cases.put(aCase.id, aCase);
        }
        
        /* end */
        for(Booking__c b : bookings)
        {           
            List<Attachment> attachments = new List<Attachment>();
            
            //if(emailMessagesByBooking.containsKey(b.id))
            //{
            MyFax_Helper myFax = new MyFax_Helper();
            
            /**** Updated by Bohao Chen JIRA SFE-82 on 11/03/2014 ****/
            myFax.addFaxRecipient(b.Placer_Contact__r.name,b.Quote_Confirmation_Fax__c, 'Booking:' + b.Name);
            /**** Updated by Bohao Chen ****/
            
            
            String emailAddr = [Select Email From User Where Id =: b.Modified_By_Copy__c limit 1].Email;
            
            myFax.confirmationEmail(emailAddr);
            
            /*system.debug('@sendBookingQuoteConfirmationFaxChunk fax comment : ' + emailMessagesByBooking.get(b.id).getHtmlBody());

myfax.setComment(emailMessagesByBooking.get(b.id).getHtmlBody());*/
            
            system.debug('@sendBookingQuoteConfirmationFaxChunk fax comment : ' + b.Fax_Content__c);
            
            //myfax.setComment(b.Fax_Content__c);
            
            system.debug('?????????booking.Fax_Content__c:'+ cases.get(bookingIDCaseID.get(b.id)).Apex_Fax_Body__c.stripHtmlTags());
            myfax.setComment(cases.get(bookingIDCaseID.get(b.id)).Apex_Fax_Body__c.stripHtmlTags());
            //      myfax.setComment('this is testing');
            
            if(myFax.documentList!=null && myFax.documentList.FaxDocument!=null)
                myFax.documentList.FaxDocument.clear();        
            
            if(b.AdProof_Required__c &&
               b.Ad_Proof_Document__c.trim().length()>=15 &&
               documents.containsKey(b.Ad_Proof_Document__c))
            {
                myfax.addDocument(documents.get(b.Ad_Proof_Document__c));
                
                Attachment att = new Attachment();
                att.body = documents.get(b.Ad_Proof_Document__c).body;
                att.name = documents.get(b.Ad_Proof_Document__c).name;
                attachments.add(att);                    
            } 
            
            
            try
            {
                system.debug(logginglevel.error, '@sendBookingQuoteConfirmationFaxChunk myfax: ' + myfax);
                
                wsMyfaxCom.SendMyFaxResult_element faxResult = myfax.sendFax(true, b.id, b.Placer_Contact__r.id, attachments);
                if(faxResult.NumberOfFailed == 0)
                {
                    faxSent.add(b.id);
                    //bookingIdFaxcontent.put(b.id,faxContent);
                }
            }
            catch (Exception ex)
            {
                system.debug('@sendBookingQuoteConfirmationFaxChunk exception: ' + ex.getMessage());
                bookingsNotSent.add(b.id);
            }
            //}      
        }
        
        
        system.debug('@ BookingManagement_Trigger_Helper sendBookingQuoteConfirmationFax bookingsNotSent.size():' + bookingsNotSent.size() );
        
        
        if(faxSent.size()>0)
        {
            BookingManagement_Trigger_Helper.updateBookingSendDateFlagNonFuture(faxSent);
            //BookingManagement_Trigger_Helper.updateBookingSendDateFlagNonFuture(bookingIdFaxcontent);
        }
        
        if(bookingsNotSent.size()>0)
        {
            Global_Helper.notifySysAdminException(bookingsNotSent, 'Quote/Confirmation for faxes could not be sent, see booking Ids', UserInfo.getUserEmail());
        }
        
    }
    
    
    // this method will set Quote_or_Confirmation_Flag_Send_Date__c to true
    // using future call is because it updates same sobject records in after update trigger
    // and there is no way to achieve this and related requirement in before update trigger
    @future
    public static void updateBookingSendDateFlag(Set<Id> bookingIds)
    {
        BookingManagement_Trigger_Helper.updateBookingSendDateFlagNonFuture(bookingIds);
        
    }
    
    
    @future
    public static void updateBookingWaitingMessageSentFlag(Set<Id> bookingIds)
    {
        BookingManagement_Trigger_Helper.updateBookingSendDateFlagNonFuture(bookingIds, false, true);
    }
    
    
    public static void updateBookingSendDateFlagNonFuture(Set<Id> bookingIds)
    {
        BookingManagement_Trigger_Helper.updateBookingSendDateFlagNonFuture(bookingIds, true, false);
    }
    
    public static void updateBookingSendDateFlagNonFuture(Set<Id> bookingIds, boolean isMessageSent, boolean isWaitingMessageSent)
    {
        if(bookingIds != null && bookingIds.size() > 0)
        {
            system.debug('===BookingManagement_Trigger_Helper:updateBookingSendDateFlag=== ' + bookingIds);
            
            List<Booking__c> bookings = [Select Quote_or_Confirmation_Flag_Send_Date__c, 
                                         Quote_Confirmation_waiting_msg_sent__c,Apex_Adproof_Previously_Sent__c
                                         From Booking__c 
                                         Where Id IN: bookingIds];
            
            for(Booking__c b : bookings)
            {
                b.Quote_or_Confirmation_Flag_Send_Date__c = isMessageSent;
                b.Quote_Confirmation_waiting_msg_sent__c = isWaitingMessageSent;
                system.debug('@updateBookingSendDateFlagNonFuture: ' + b.Quote_Confirmation_waiting_msg_sent__c);
                
                //*********
                //Added on 21 Feb 2014, by Jack: SFE39 �  When creating a NEW booking confirmation - the Adproof checkbox should be ticked
                //The first time a fax or email confirmation is sent (with or without errorrs) - we check this checkbox.
                if(b.Quote_Confirmation__c=='Confirmation' && b.Apex_Adproof_Previously_Sent__c==false){
                    b.Apex_Adproof_Previously_Sent__c=true;
                }
                //*********
            }
            
            // 2016-02-25 atul.gupta@bluewolfgroup.com - SFE-824 Exception Log framework method added to catch any exceptions on DML
            try{
                update bookings;
            } catch(Exception ex){
                ExLog.log(ex, 'config', bookings, 'SFE-824 Update Booking Nunber on Case');
            }
        }
        
    }
    
    public static void updateOpportunityStageName(Map<id,Booking__c> newMap, Map<id,Booking__c> oldMap)
    {
        Map<String, Booking_Oppty_Status_Map__c> cs = Booking_Oppty_Status_Map__c.getAll();
        List<Booking__c> bookingWithChangedStatus = new List<Booking__c>();
        
        for(booking__c bo : newMap.values())
        {
            // SFE-795 2016-01-26 darshan.gosar@bluewolfgroup.com 
            //  Added Source System as Cyber$ell check to avoid other booking updates               
            if(cs.containsKey(bo.Status__c) && bo.Source_System__c == 'Cyber$ell' &&            
               ((oldMap!=null && bo.Status__c != oldMap.get(bo.id).Status__c) || oldMap==null))
            {
                bookingWithChangedStatus.add(bo);
            }
        }
        
        if(bookingWithChangedStatus.size()>0)
        {
            List<Opportunity> opportunityToUpdate = setOpptyStageNameBasedOnBookingStatus(getopptyIdByBooking(bookingWithChangedStatus));
            if(opportunityToUpdate.size()>0)
            {
                // 2016-02-25 atul.gupta@bluewolfgroup.com - SFE-824 Exception Log framework method added to catch any exceptions on DML
                try{
                    update opportunityToUpdate;
                } catch(Exception ex){
                    ExLog.log(ex, 'config', opportunityToUpdate, 'SFE-824 List of Opportunities updated');
                }
            }
        }
    }
    
    
    
    
    private static map<Booking__c, Id> getopptyIdByBooking (List<Booking__c> bos)
    {
        map<Booking__c, id> opptyIdByBooking = new map<Booking__c, id>();
        map<id, List<Booking__c>> boBySoId = new map<id, List<Booking__c>>();
        for(Booking__c bo : bos)
        {
            if(boBySoId.containsKey(bo.Sales_Order__r.id))
            {
                boBySoId.get(bo.Sales_Order__c).add(bo);
            }
            else
            {
                boBySoId.put(bo.Sales_Order__c, new List<Booking__c>{bo});
            }
        }
        
        System.debug(LoggingLevel.ERROR, '@BookingManagement_Trigger_Helper.getopptyIdByBooking boBySoId:' + boBySoId);
        
        map<Sales_Order__c, List<OpportunityLineItem>> oliBySoId = new map<Sales_Order__c, List<OpportunityLineItem>>();
        for(OpportunityLineItem oli : [Select id, OpportunityId, Opportunity.StageName, Sales_Order__c
                                       from OpportunityLineItem
                                       where Sales_Order__c IN : boBySoId.keySet()])
        {
            for(Booking__c bo : boBySoId.get(oli.Sales_Order__c))
            {
                // SFE-795 2016-01-26 darshan.gosar@bluewolfgroup.com 
                //  Added StageName as Reservation check to avoid closed won & closed lost Opportunity updates              
                if(oli.Opportunity.StageName == 'Reservation')
                    opptyIdByBooking.put(bo, oli.OpportunityId);
            }
        }
        return opptyIdByBooking;
    }
    
    
    private static List<Opportunity> setOpptyStageNameBasedOnBookingStatus(Map<Booking__c, id> opptyIdByBooking)
    {
        Map<String, Booking_Oppty_Status_Map__c> cs = Booking_Oppty_Status_Map__c.getAll();
        List<Opportunity> opptyList = new List<Opportunity>();
        
        for(Booking__c bo : opptyIdByBooking.keySet())
        {           
            if(cs.containsKey(bo.Status__c))
            {
                opptyList.add(new Opportunity(  id=opptyIdByBooking.get(bo),
                                              StageName=cs.get(bo.Status__c).OpptyStatus__c,
                                              Reason_Won_Lost__c=cs.get(bo.Status__c).OpptyReason__c));
            }
        }
        
        return opptyList;
    }
    
}