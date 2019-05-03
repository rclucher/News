/*------------------------------------------------------------  
Author:        Paras Prajapati
Company:       Salesforce.com
Description:   Controller class, will be used by the NXX2_ContactListPageController Component 
Test Class:    ...
History
<Date>      <Authors Name>     <Brief Description of Change>
01/11/2018  Paras Prajapati    This class will be used to fetch all the contacts search by the User in Account Home Page 
------------------------------------------------------------*/
public without sharing class NXX2_ContactListPageController {
    @AuraEnabled
    /**
     * getTotalCount description  - This method will fetch total number records exist, with the given email Ids.
     * @param  searchKeyword searchKeyword description
     * @return               return numbe of records available for given email address.
     */
    public static Integer getTotalCount(String searchKeyword){
		searchKeyword  = '%' + searchKeyword + '%';
        system.debug('*****Search: '+ searchKeyword);
        AggregateResult results = [select  count(Id) total  from Contact where Email LIKE :searchKeyword];
        Integer total =(Integer)results.get('total') ; 
        system.debug('*****Count: '+ total);
        return total;
    } 
    
    @AuraEnabled
    /**
     * getContacts description
     * @param  limits        limits - how many records need to be query.
     * @param  offsets       offsets 10 
     * @param  searchKeyword searchKeyword  email address entered by the user.
     * @return               return List Of contact return based on limit and offset.
     */
    public static List<Contact> getContacts(Integer limits , Integer offsets,String searchKeyword){
		searchKeyword  = '%' + searchKeyword + '%';
        Integer intlimits = integer.valueof(limits);
        Integer intoffsets = integer.valueof(offsets);
        system.debug('*****Ini: '+ intlimits);
        system.debug('*****Offset: '+ intoffsets);
        List<Contact> contacts = [Select Name,FirstName,LastName,Phone,Department,Fax,Email,CreatedDate,AccountId from Contact where Email LIKE :searchKeyword Order by Name Limit :intlimits Offset :intoffsets];
        system.debug('*****Record: '+ contacts);
        return contacts;
    }
}