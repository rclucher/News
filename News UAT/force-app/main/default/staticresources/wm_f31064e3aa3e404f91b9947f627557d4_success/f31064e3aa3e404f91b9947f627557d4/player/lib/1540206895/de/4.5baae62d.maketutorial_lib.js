window.walkMeGermany = true;_walkmeWebpackJP([4],{197:function(n,e,t){(function(t,e){t.register("IntegrationCenterWebhooksInitializer").asCtor(function(l,g,u,f,d,C,p,S,h,k){this.start=function(c){return new e(function(n,r){try{var e=f.getSettingsFile(),t=f.getCdnServerName();if(p.isSelfHosted){if(a=m,!((o=c.SiteConfig)&&o.Features&&"function"==typeof o.Features.indexOf&&~o.Features.indexOf(a)))return n();t=e.PlayerApiServer&&e.PlayerApiServer.replace("papi","cdn")}var i=localStorage.getItem("wm-integration-center-webhooks-snippet-link")||t+"/ic/webhooks/0/main.js";l.addScriptWithCallback(i,"onIntegrationCenterWebhooksReadyCb",function(e){try{e.init({dataFile:c,wmInternals:p,consts:u,userGuidContainer:C,wmjQuery:d,wmLogger:g,clientStorageManager:S,settingsFile:f,classWalkMeAPI:h,eventSender:k}).then(function(){n()})["catch"](function(e){r(e)})}catch(t){r(t)}},function(){r(new Error("Failed to addScriptWithCallback for: "+i))})}catch(s){r(s)}var a,o})},function(){}.apply(null,arguments)}).dependencies("CommonUtils, Logger, Consts, SettingsFile, wmjQuery, UserGuidContainer, WmInternals, ClientStorageManager, ClassWalkMeAPI, EventSender");var m="IntegrationCenterWebhooksAllowedInSelfHosted";n.exports={init:function(e){return t.get("IntegrationCenterWebhooksInitializer").start(e)["catch"](function(e){t.get("Logger").error(e)})}}}).call(e,t(2),t(29))}});
