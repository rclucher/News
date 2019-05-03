trigger PackageName on cscfga__Product_Configuration__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    system.debug('Sales Order Trigger');
    if(Trigger.isInsert && Trigger.isAfter){
        PackageNameHelper.AddPackageInsert(Trigger.New);
    }

    if(Trigger.isUpdate && Trigger.isAfter){
        PackageNameHelper.AddPackageUpdate(Trigger.New);
    }
}