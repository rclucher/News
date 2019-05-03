CSMLEAPI.gridOptions = {
    statusColWidth: 50,
    savedColWidth: 50
};


CSMLEAPI.Formatters.DateAttributeFormatter =  function(row, cell, value, columnDef, dataContext) {
    var html = '';
    
    if (!value.cscfga__is_active__c) {
      html = '<div class="disabled"></div>';
      return html;
    }

    var css = '';
    if (value.cscfga__Is_Read_Only__c) {
      css = 'readonly';
    }
    
    html = '<div class="'+css+'"></div>';
    
    if (value.cscfga__Value__c !== null && value.cscfga__Value__c !== "") {
      html = '<div class="'+css+'">' + new Date(value.cscfga__Value__c).toLocaleDateString(UserContext.locale) + '</div>';
    }
    
    if (value.validationMessage && value.validationMessage !== "") {
      html += ' <div class="witherror" title="'+value.validationMessage+'"></div>';
    }
    
    return html; 
};

CSMLEAPI.Formatters.CurrencyAttributeFormatter =  function(row, cell, value, columnDef, dataContext) {
    
    var currencyLocale = {"en-AU": "AUD", "en-US": "USD", "en-GB" : "GBP"};
    var options = {style: 'currency', currency: currencyLocale[UserContext.locale], currencyDisplay: 'symbol'};
    
    var html = '';
    
    if (!value.cscfga__is_active__c) {
      html = '<div class="disabled"></div>';
      return html;
    }

    var css = '';
    if (value.cscfga__Is_Read_Only__c) {
      css = 'readonly';
    }
    
    html = '<div class="'+css+'"></div>';
    
    if (value.cscfga__Value__c !== null && value.cscfga__Value__c !== "") {
      html = '<div class="'+css+'">' + Number(value.cscfga__Value__c).toLocaleString(UserContext.locale,options) + '</div>';
    }
    
    if (value.validationMessage && value.validationMessage !== "") {
      html += ' <div class="witherror" title="'+value.validationMessage+'"></div>';
    }
    
    return html; 
};

CSMLEAPI.Formatters.ApprovalLevelAttributeFormatter =  function(row, cell, value, columnDef, dataContext) {
    
    var html = '';
    
    if (!value.cscfga__is_active__c) {
      html = '<div class="disabled"></div>';
      return html;
    }

    var css = '';
    if (value.cscfga__Is_Read_Only__c) {
      css = 'readonly';
    }
    
    html = '<div class="'+css+'"></div>';
    
    if (value.cscfga__Value__c !== null && value.cscfga__Value__c !== "") {
      html = '<div class="'+css+'">' + 'Level ' + value.cscfga__Value__c + '</div>';
    }
    
    if (value.validationMessage && value.validationMessage !== "") {
      html += ' <div class="witherror" title="'+value.validationMessage+'"></div>';
    }
    
    return html; 
};