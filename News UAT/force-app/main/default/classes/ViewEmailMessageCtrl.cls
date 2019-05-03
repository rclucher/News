// 2017-09-28 darshan.gosar@bluewolfgroup.com 
// This is apex class created as controller for ViewEmailMessage & EmailMessagePreview VF pages as part of AdSales 353
public class ViewEmailMessageCtrl{
    //public static FINAL String NO_CASE = 'Cannot be forwarded as Parent Case is empty';
    public static FINAL String NO_PLACER_CUSTOM = 
        'Please select either of placer/custom contact checkbox';
    public static FINAL String NO_PLACER_CONTACT = 
        'Cannot be forwarded as there`s no placer contact present on the related booking record';
    public static FINAL String NO_CUSTOM_CONTACT = 
        'Please enter a contact';
    public static FINAL String NO_EMAIL = 'Cannot be forwarded as there`s no email address populated on related contact record';
    public EmailMessage displayMsg2 {get; set;}
    public Booking__c relatedBookingRecord {get; set;}
    public Case parentCase {get; set;}
    public Boolean sendToPlacer {get; set;}
    public Boolean sendToCustom {get; set;}
    
    public ViewEmailMessageCtrl(ApexPages.StandardController controller) {
        parentCase = new Case();
        relatedBookingRecord = new Booking__c();
        sendToPlacer = sendToCustom = false;
    }
    
    public pagereference checkEmailMessage(){
        String messageId = ApexPages.currentPage().getParameters().get('Id');
        
        if(messageId != null && messageId != ''){
            
            List<EmailMessage> eList = new List<EmailMessage>();
            
            eList = [Select Id, HtmlBody, RelatedToId, TextBody, FromName, FromAddress,
                     Subject, ParentiD, Parent.contactid, LastModifiedById, CreatedById, Status,
                     MessageDate, ToAddress, CcAddress, BccAddress
                     FROM EmailMessage WHERE Id = :messageId Limit 1];
            
            if(eList.size() > 0 && eList[0].RelatedToId != null && String.valueOf(eList[0].RelatedToId).startsWith('a1Q')){
                displayMsg2 = eList[0];
                relatedBookingRecord = [Select id, Placer_Contact__c from Booking__c where id=: displayMsg2.RelatedToId][0];
                return null;                 
            }
            else{                
                PageReference ReturnPage = new PageReference('/' + messageId + '?nooverride=1');
                ReturnPage.setRedirect(true);
                return ReturnPage; 
            }
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'No Email Message Id found in URL'));
            return null;
        }
    }
    public pagereference sendToContactAndAttachToCase(){
        /*if(displayMsg2.ParentId == null){
ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, NO_CASE));
}*/
        if(!sendToPlacer && !sendToCustom){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, NO_PLACER_CUSTOM));
        }else{
            //booking placer  or custom lookup
            Messaging.SingleEmailMessage[] mails = new List<Messaging.SingleEmailMessage>();
            if(sendToPlacer){
                if(relatedBookingRecord.Placer_Contact__c == null)
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING,
                                                               NO_PLACER_CONTACT));
                else
                    mails.add(createSingleEmail(relatedBookingRecord.Placer_Contact__c,
                                                displayMsg2, parentCase.parentId));
            }
            if(sendToCustom)
            {
                system.debug('parentCase.contactId '+parentCase.contactId);
                if(parentCase.contactId == null)
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING,
                                                               NO_CUSTOM_CONTACT));
                else
                    mails.add(createSingleEmail(parentCase.contactId,
                                                displayMsg2, parentCase.parentId));
            }
            if(!mails.isEmpty()){
                try{
                    Messaging.sendEmail(mails);
                    return new PageReference('/'+ parentCase.ParentId);
                }
                catch(Exception ex){
                    if(ex.getMessage().contains('Add a recipient to send an email')){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, NO_EMAIL));
                    }
                    else ApexPages.addMessages(ex);                
                }
            }
        }
        return null;
    }
    public Messaging.SingleEmailMessage createSingleEmail(Id targetId, EmailMessage outboundMail, Id parentCaseId){
        String textBody = outboundMail.TextBody==null?' ':outboundMail.TextBody;
        String htmlBody = outboundMail.HtmlBody==null?' ':outboundMail.HtmlBody;
        
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();        
        m.setTargetObjectId(targetId);//displayMsg2.Parent.contactid
        m.setWhatId(parentCaseId);
        m.setSaveAsActivity(true);
        m.setSubject(displayMsg2.subject);
        m.setPlainTextBody(textBody); 
        m.setHtmlBody(htmlBody);
        return m;        
    }
}