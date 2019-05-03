/**
 * Created by petar.mikic on 20/07/2018.
 */
@IsTest
public without sharing class CS_MediaHelperTest {
    @testSetup
    static void setupData() {
        List<String> platformKeys = new List<String>{
                '{Print, Xtend}', '{Digital, Print, Xtend}', '{Digital}', '{Digital, Xtend}', '{Digital, Print}', '{Xtend}', '{Print}', ''
        };

        String SOSpecName = 'NextGen Sprint ';

        List<csmso__Sales_Order_Summary_Spec__c> soSpecs =  new List<csmso__Sales_Order_Summary_Spec__c>();

        for(String pKey: platformKeys) {
            soSpecs.add( new csmso__Sales_Order_Summary_Spec__c(
                    Name = SOSpecName + pKey,
                    csmso__Priority__c = -20,
                    csmso__Key__c = pKey
            ));
        }

        insert soSpecs;
        
    }

    @IsTest
    static void testSOSpecGeneration() {

            CS_MediaHelper.generateSOSPecRecords();
    }
}