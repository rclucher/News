//Generated by wsdl2apex

public class AsyncESB_GetNetDAForGBAStub {
    public class getDAForGBAResponseFuture extends System.WebServiceCalloutFuture {
        public ESB_GetNetDAForGBAStub.getDAForGBAResponse getValue() {
            ESB_GetNetDAForGBAStub.getDAForGBAResponse response = (ESB_GetNetDAForGBAStub.getDAForGBAResponse)System.WebServiceCallout.endInvoke(this);
            return response;
        }
    }
    public class Asyncnews_adapter_xref_wsdl_getDAForGBA_Port {
        public String endpoint_x = 'http://wmnmbsdev01.news.newslimited.local:5555/ws/news.adapter.xref.wsdl:getDAForGBA/news_adapter_xref_wsdl_getDAForGBA_Port';
        public Map<String,String> inputHttpHeaders_x;
        public String clientCertName_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'http://NSGMCTWMDEV02V.news.newslimited.local/news.adapter.xref.wsdl:getDAForGBA', 'ESB_GetNetDAForGBAStub'};
        public AsyncESB_GetNetDAForGBAStub.getDAForGBAResponseFuture beginGetDAForGBA(System.Continuation continuation,String GBA,String NMBSDivision) {
            ESB_GetNetDAForGBAStub.getDAForGBA request_x = new ESB_GetNetDAForGBAStub.getDAForGBA();
            request_x.GBA = GBA;
            request_x.NMBSDivision = NMBSDivision;
            return (AsyncESB_GetNetDAForGBAStub.getDAForGBAResponseFuture) System.WebServiceCallout.beginInvoke(
              this,
              request_x,
              AsyncESB_GetNetDAForGBAStub.getDAForGBAResponseFuture.class,
              continuation,
              new String[]{endpoint_x,
              'news_adapter_xref_wsdl_getDAForGBA_Binder_getDAForGBA',
              'http://NSGMCTWMDEV02V.news.newslimited.local/news.adapter.xref.wsdl:getDAForGBA',
              'getDAForGBA',
              'http://NSGMCTWMDEV02V.news.newslimited.local/news.adapter.xref.wsdl:getDAForGBA',
              'getDAForGBAResponse',
              'ESB_GetNetDAForGBAStub.getDAForGBAResponse'}
            );
        }
    }
}