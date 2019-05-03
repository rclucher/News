/*---------------------------------------------------------
author: Allanah Mae
Company: Salesforce.com
description: Handles creation of GBA in SF and genera
History:
07-03-2017  Allanah Mae  Created
---------------------------------------------------------*/
public class ESB_GetDAForGBA_Helper {
    ESB_GetNetDAForGBAStub.news_adapter_xref_wsdl_getDAForGBA_Port GetNetDAForGBAWebservice;

    public ESB_GetDAForGBA_Helper() {
        this.GetNetDAForGBAWebservice = new ESB_GetNetDAForGBAStub.news_adapter_xref_wsdl_getDAForGBA_Port();
    }

    public ESB_GetNetDAForGBAStub.getDAForGBAResponse getNetDA(String gba) {
        //From AdSales-00240: NewsAdds Post Pay Feedback 2 - Pass in the GBA and the NMBSDivision as NOZ
        String nmbsDivision = 'NOZ';

        ESB_GetNetDAForGBAStub.getDAForGBAResponse response = GetNetDAForGBAWebservice.getDAForGBA(gba, nmbsDivision);

        return response;
    }

}