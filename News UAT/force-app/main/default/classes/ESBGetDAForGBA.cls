global without sharing class ESBGetDAForGBA {

    webService static List<String> getDAForGBA(String gba)
    {
        List<String> esbResponse = new List<String>();

        ESB_GetDAForGBA_Helper esb = new ESB_GetDAForGBA_Helper();
        
        ESB_GetNetDAForGBAStub.getDAForGBAResponse daForGBAResponse;

        try {
            daForGBAResponse = esb.getNetDA(gba);
        }
        catch (Exception e) {
            esbResponse.add('ERROR');
            esbResponse.add(e.getMessage());
        }

        System.debug('daForGBAResponse.response = ' + daForGBAResponse.response);

        if (daForGBAResponse != null && daForGBAResponse.response == 'SUCCESS') {
            System.debug('@success');
            //search for NET_DA and set as BSA_Net_DA__c for  booking system account
            
            String netDA = daForGBAResponse.da;
            
            esbResponse.add('SUCCESS');
            esbResponse.add(netDA);
            System.debug('ESBGetDAForGBA SUCCESS');
        }
        else if (daForGBAResponse != null && daForGBAResponse.response == 'DA doesn\'t exist in GBA/BA table') {
            System.debug('@does not exist');

            //create a net da via cybersell
            ExternalAccountCreateGBA_Helper createGBAHelper = new ExternalAccountCreateGBA_Helper();
            createGBAHelper.login();
            createGBAHelper.setAccount(gba, '^Attributes([Attribute.Code]=\'NEWACCRQ\').Detail', 'National');
            createGBAHelper.setAccount(gba, '^Attributes([Attribute.Code]=\'NEWACCRQ\').State.Code', 'ISREQ');

            // 2017-09-28 AdSales 350 darshan.gosar@bluewolfgroup.com Added StartDate attribute based on confirmation from Peter
            createGBAHelper.setAccount(gba, '^Attributes([Attribute.Code]=\'NEWACCRQ\').StartDate', String.valueOf(System.Now()));
            createGBAHelper.saveAccount(gba);
            createGBAHelper.logout();

            esbResponse.add('CREATE');
            esbResponse.add(daForGBAResponse.response);
            System.debug('ESBGetDAForGBA CREATE');

        }
        else if (daForGBAResponse != null) {
            //null is covered in the try/catch block
            //System.debug('@other failure');
            System.debug('ESBGetDAForGBA FAIL');
            esbResponse.add('ERROR');
            esbResponse.add(daForGBAResponse.response);
        }

        return esbResponse;
    }
    
}