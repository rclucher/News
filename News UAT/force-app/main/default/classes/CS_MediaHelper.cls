/**
 * Created by petar.mikic on 13/07/2018.
 */

public with sharing class CS_MediaHelper {

    public static void generateSOSPecRecords() {
        List<csmso__Sales_Order_Summary_Spec__c> sossList = [SELECT Id, Name, csmso__Key__c FROM csmso__Sales_Order_Summary_Spec__c
        WHERE Name Like 'NextGen Sprint%'];

        if (sossList.size() == 0) {
            System.debug('*** No summary specs exist to update');
            return;
        }

        List<StaticResource> srList = [SELECT Id,Name, Body FROM StaticResource WHERE Name LIKE 'SOSpec%'];

        if (srList.size() == 0 || srList.size() != 7) {
            System.debug('*** Summary spec static resources mismatch. Not updating anything');
            return;
        }

        Map<String,String> specNameToValueMap = new Map<String, String>();

        for (StaticResource sr: srList) {
            System.debug(sr.Name);
            String body = sr.Body.toString();
            specNameToValueMap.put(sr.Name,body);
        }
        String refPlatforms = '{Digital, Print, Xtend}';
        Integer totalPlatforms = 0;
        String  platforms = '';

        for (csmso__Sales_Order_Summary_Spec__c soss: sossList) {
            System.debug(' >>> Running through ' + soss.Name + ' spec record ');

            platforms = (soss.csmso__Key__c != null) ? soss.csmso__Key__c : '';
            System.debug('Has " ' + platforms + ' " platforms');
            totalPlatforms = platforms.split(',').size();

            soss.csmso__JSON__c = specNameToValueMap.get('SOSpecDetails');

            //if product sections exist JSON will fail without comma
            //if (platforms != '') soss.csmso__JSON__c += ',';

            System.debug('Details set.');

           /* if(platforms.contains('Bundle')) {
            	System.debug('Added Bundle section');
            	soss.csmso__JSON__c += ',';
            	soss.csmso__JSON__c += specNameToValueMap.get('SOSpecBundleSection');
            	//if (platforms.contains('Xtend')) soss.csmso__JSON__c += ',';
            }
            
            if (platforms.contains('Digital')) {
                System.debug('Added Digital section');
                soss.csmso__JSON__c += ',';
                soss.csmso__JSON__c += specNameToValueMap.get('SOSpecDigitalSection');
                
            }*/

            if (platforms.contains('Print')) {
                System.debug('Added Print section');
                soss.csmso__JSON__c += ','; 
                soss.csmso__JSON__c += specNameToValueMap.get('SOSpecPrintSection');
                               
            }

            if (platforms.contains('Xtend')) {
                System.debug('Added Xtend section');
                soss.csmso__JSON__c += ',';
                soss.csmso__JSON__c += specNameToValueMap.get('SOSpecXtendSection');
                
            }
             
            soss.csmso__JSON__c += specNameToValueMap.get('SOSpecAdministrativeInfo');
            System.debug('Added Administrative Info Section');
                    
            soss.csmso__JSON__c += specNameToValueMap.get('SOSpecButtonsAndLineItems');
            System.debug('Added Buttons and Line Items');

            soss.csmso__Field_Names_CSV__c = specNameToValueMap.get('SOSpecFieldNames');
            System.debug('FieldNames set');

		}

        update sossList;

    }

}