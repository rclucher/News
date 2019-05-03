public with sharing class ChecklistViewCtrl {
	public List<QA_Item__c> qaitems { get; set; }
	public List<ItemWrap> listWrap { get; set; }
	public List<SelectOption> values { get; set; }
	public String objectid { get; set; }

	public ChecklistViewCtrl(ApexPages.StandardController stdController) 
    {
    	values = new List<SelectOption>();

        values.add(new SelectOption ('Pass', 'Pass'));
        values.add(new SelectOption ('Fail', 'Fail'));
        values.add(new SelectOption ('N/A', 'N/A'));

    	List<QA_Item__c> qaitems = new list<QA_Item__c>();
    	listWrap = new List<ItemWrap>();
    	objectid = stdController.getId();

    	string query = 'select id, Item__c, Result__c, Note__c from QA_Item__c where QA_Checklist__c =: objectid';
    	qaitems = database.query(query);
    	for (QA_Item__c i : qaitems) {
    		listWrap.add (new ItemWrap (i));
    	}
    }

    public PageReference save () {
    	List<QA_Item__c> qaitems = new list<QA_Item__c>();
    	for (ItemWrap item : listWrap) {
    		item.item.Result__c = item.value;
    		qaitems.add(item.item);
    	}
    	update qaitems;
    	return null;
    }

    public class ItemWrap {
    	public QA_Item__c item { get; set; }
    	public String value {get; set;}

    	public ItemWrap (QA_Item__c itemPar) {
    		this.item = itemPar;
    		this.value = itemPar.Result__c;
    	}
    }

}