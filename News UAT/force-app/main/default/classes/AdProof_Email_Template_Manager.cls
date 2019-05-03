/**
* @author Leonardo Mancilla
* @Company Bluewolf (Beyond)
* @Description
*  SFE-445
*  	'When view email in Case/Outbound email message is shows the generic template not filled in. But HTML version shows it was. Case should reflect the same text as HTML version
*	Business Case:
*		At a glance you can see the email wording sent without needing to click into the HTML to view the “real” text of the email.'
*
* History:
* 20/11/2013  Leonardo Mancilla - Created
**/

public with sharing class AdProof_Email_Template_Manager {
    
    /**
* Loops through a list of Email Messages and checks of the subject contains 'Ad Proof'
* If so, it changes the text version of the email to reflect the changes made by the users
* @param messages List of email messages to be evaluated	
**/	
    public void evaluateEmailMessages(List<EmailMessage> messages){
        String ans='';
        
        for(EmailMessage em:messages){
            //System.debug('BEOFRE IF '+em.Subject);
            if((em.Subject!=null)&&(em.Subject.containsIgnoreCase('Ad Proof'))){
                //System.debug('INSIDE IF '+em.Subject.trim());
                if(em.HtmlBody!=null)
                    em.TextBody=parseHTML(em.HtmlBody);//.replaceAll('(\\<.*?>)', '');
                //System.debug('REPLACE IF '+em.TextBody);
            }
        }		
    }
    
    /**
* <p>Parses the HTMLContent of an email message and returns the text representation with no tags	
* Adapted from http://www.codeproject.com/Articles/11902/Convert-HTML-to-Plain-Text
* Uses regular expressions to make the replacements. Some tags are not currently used in the email templates
* but are used in this method to avoid future issues with some tags.</p>
* @param htmlContent The rich text content of the email message	
* @return String The text version of the HTMLContent
**/			
    private String parseHTML(String htmlContent){
        
        System.debug('@htmlContent before parsing: ' + htmlContent);
        
        String result='';
        // Remove HTML Development formatting
        // Replace line breaks with space
        // because browsers inserts space
        result = htmlContent.replaceAll('\n', ' ');
        htmlContent=result;
        // Replace line breaks with space
        // because browsers inserts space
        result = htmlContent.replaceAll('\n', ' ');
        htmlContent=result;
        
        // Remove step-formatting
        result = htmlContent.replaceAll('\t','');
        htmlContent=result;
        // Remove repeating spaces because browsers ignore them
        result = htmlContent.replaceAll('( )+', ' ');
        htmlContent=result;
        
        // Remove the header (prepare first by clearing attributes)
        result = htmlContent.replaceAll( '<( )*head([^>])*>','<head>');
        htmlContent=result;
        result = htmlContent.replaceAll('(<( )*(/)( )*head( )*>)','</head>');
        htmlContent=result;
        result = htmlContent.replaceAll('(<head>).*(</head>)','');
        htmlContent=result;
        
        // remove all styles (prepare first by clearing attributes)
        result = htmlContent.replaceAll('<( )*style([^>])*>','<style>');
        htmlContent=result;
        result = htmlContent.replaceAll('(<( )*(/)( )*style( )*>)','</style>');
        htmlContent=result;
        result = htmlContent.replaceAll('(<style>).*(</style>)','');
        htmlContent=result;
        
        // insert tabs in spaces of <td> tags
        result = htmlContent.replaceAll('(?i)<( )*td([^>])*>','\t');
        htmlContent=result;
        
        // insert line breaks in places of <BR> and <LI> tags
        result = htmlContent.replaceAll('(?i)<( )*br( )*>','\n');
        htmlContent=result;
        result = htmlContent.replaceAll('(?i)<( )*li( )*>','\n');
        htmlContent=result;
        
        // insert line paragraphs (double line breaks) in place
        // if <P>, <DIV> and <TR> tags
        result = htmlContent.replaceAll('(?i)<( )*div([^>])*>','\n');
        htmlContent=result;
        result = htmlContent.replaceAll('(?i)<( )*tr([^>])*>','\n');
        htmlContent=result;
        result = htmlContent.replaceAll('(?i)<( )*p([^>])*>','\n');
        htmlContent=result;
        
        // Remove remaining tags like <a>, links, images,
        // comments etc - anything that's enclosed inside < >
        result = htmlContent.replaceAll('(?i)<[^>]*>','');
        htmlContent=result;
        
        // replace special characters:
        result = htmlContent.replaceAll(' ',' ');
        htmlContent=result;
        
        result = htmlContent.replaceAll('&bull;',' * ');
        htmlContent=result;
        result = htmlContent.replaceAll('&lsaquo;','<');
        htmlContent=result;
        result = htmlContent.replaceAll('&rsaquo;','>');
        htmlContent=result;
        result = htmlContent.replaceAll('&trade;','(tm)');
        htmlContent=result;
        result = htmlContent.replaceAll('&frasl;','/');
        htmlContent=result;
        result = htmlContent.replaceAll('&lt;','<');
        htmlContent=result;
        result = htmlContent.replaceAll('&gt;','>');
        htmlContent=result;
        result = htmlContent.replaceAll('&copy;','(c)');
        htmlContent=result;
        result = htmlContent.replaceAll('&reg;','(r)');
        htmlContent=result;
        // Remove all others. More can be added, see
        // http://hotwired.lycos.com/webmonkey/reference/special_characters/
        result = htmlContent.replaceAll('&(.{2,6});','');
        htmlContent=result;
        
        System.debug('@htmlContent after parsing: ' + htmlContent);
        
        return result;	
    }
}