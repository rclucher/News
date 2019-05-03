/**
 * Simple builder for MLE url.
 */
public class MleUrlBuilder {

    private static String editorUrlPart = 'Editor';
    private static String basketIdUrlPart = '?id=';
    private static String batchSizeUrlPart = '&batchSize=';
    private static String sideBarUrlPart = '&sideBar=';
    private static String showHeaderUrlPart = '&showHeader=';
    private static String productDefinitionIdUrlPart = '&productDefinitionId=';
    private static String configFilterUrlPart = '&configFilter=';
    private static String cssOverride = '&cssoverride=/resource/';
    private static String scriptPlugin = '&scriptPlugin=/resource/';

    private String url;
    private id basketId;
    private id definitionId;
    private Integer batchSize;
    private Boolean sideBar;
    private Boolean showHeader;
    private String configFilter;
    private Map<String, String> parameterValues;
    private String cssFileName;
    private String scriptPluginName;

    /**
     * Constructor. All other parameters not in constructor are optional.
     */
    public MleUrlBuilder(String baseUrl, Id  productBasketId, Id productDefinitionId) {
        this.url = baseUrl;
        this.basketId = productBasketId;
        this.definitionId = productDefinitionId;
    }

    public MleUrlBuilder setBatchSize(Integer size) {
        this.batchSize = size;
        return this;
    }

    public MleUrlBuilder setSideBar(Boolean showSideBar) {
        this.sideBar = showSideBar;
        return this;
    }

    public MleUrlBuilder setShowHeader(Boolean showHeader) {
        this.showHeader = showHeader;
        return this;
    }

    public MleUrlBuilder setConfigFilter(String className, Map<String, String> parameterValueMap) {
        //this.configFilter = className;
        this.parameterValues = parameterValueMap;
        return this;
    }

    public MleUrlBuilder setCssOverride(String cssFileName) {
        this.cssFileName = cssFileName;
        return this;
    }


    public MleUrlBuilder setScriptPlugin(String scriptPluginName) {
        this.scriptPluginName = scriptPluginName;
        return this;
    }

    /**
     * This method will take all provided parameter and create a URL and return it in a String.
     */
    public String build() {
        String returnUrl = url;

        returnUrl += editorUrlPart + basketIdUrlPart + basketId;
        returnUrl += productDefinitionIdUrlPart + definitionId;

        if (this.batchSize != null) {
            returnUrl += batchSizeUrlPart + batchSize;
        }

        if (this.sideBar != null) {
            returnUrl += sideBarUrlPart + sideBar;
        }

        if (this.showHeader != null) {
            returnUrl += showHeaderUrlPart + showHeader;
        }

        if (this.cssFileName != null) {
            returnUrl += cssOverride + cssFileName;
        }

        if (this.scriptPluginName!= null) {
            returnUrl += scriptPlugin + scriptPluginName;
        }
        
        if (parameterValues != null) {
            for(String parameterKey : parameterValues.keySet()) {
                returnUrl += '&' + parameterKey + '=' + parameterValues.get(parameterKey);
            }
        }

        return returnUrl;
    }
}