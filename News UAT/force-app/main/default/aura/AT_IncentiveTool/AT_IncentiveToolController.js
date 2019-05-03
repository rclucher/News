({
	goBack: function(component, event, helper) {
        window.history.back();
    },
    calc: function (component, event, helper) {
        var height = 200;
        
        var regionalTeam = component.find("regionalTeam").get('v.checked'); //Boolean(component.get("v.regionalTeam"));
        var quarterlyRole = component.find("quarterlyRole").get('v.checked');
        var programmaticRole = component.find("programmaticRole").get('v.checked');
        
        var printTarget1 = Number(component.get("v.printTarget1"));
        var printTarget2 = Number(component.get("v.printTarget2"));
        var printTarget3 = Number(component.get("v.printTarget3"));
        var printTargetQ = printTarget1 + printTarget2 + printTarget3;
        
        component.set("v.printTargetQ", printTargetQ);
        
        var digitalTarget1 = Number(component.get("v.digitalTarget1"));
        var digitalTarget2 = Number(component.get("v.digitalTarget2"));
        var digitalTarget3 = Number(component.get("v.digitalTarget3"));
        var digitalTargetQ = digitalTarget1 + digitalTarget2 + digitalTarget3;
        
        component.set("v.digitalTargetQ", digitalTargetQ);
        
        var printAchieved1 = Number(component.get("v.printAchieved1"));
        var printAchieved2 = Number(component.get("v.printAchieved2"));
        var printAchieved3 = Number(component.get("v.printAchieved3"));
        var printAchievedQ = printAchieved1 + printAchieved2 + printAchieved3;
        
        component.set("v.printAchievedQ", printAchievedQ);
        
        var digitalAchieved1 = Number(component.get("v.digitalAchieved1"));
        var digitalAchieved2 = Number(component.get("v.digitalAchieved2"));
        var digitalAchieved3 = Number(component.get("v.digitalAchieved3"));
        var digitalAchievedQ = digitalAchieved1 + digitalAchieved2 + digitalAchieved3;
        
        component.set("v.digitalAchievedQ", digitalAchievedQ);
        
        var programmatic1 = component.find("programmatic1").get('v.checked');
        var programmatic2 = component.find("programmatic2").get('v.checked');
        var programmatic3 = component.find("programmatic3").get('v.checked');
        var programmaticQ = component.find("programmaticQ").get('v.checked');

        var combinedAchieved1 = printAchieved1 + digitalAchieved1;
        var combinedAchieved2 = printAchieved2 + digitalAchieved2;
        var combinedAchieved3 = printAchieved3 + digitalAchieved3;
        var combinedAchievedQ = printAchievedQ + digitalAchievedQ;
        
        component.set("v.combinedAchieved1", combinedAchieved1);
        component.set("v.combinedAchieved2", combinedAchieved2);
        component.set("v.combinedAchieved3", combinedAchieved3);
        //component.set("v.combinedAchievedQ", combinedAchievedQ);
        
        var combinedTarget1 = printTarget1 + digitalTarget1;
        var combinedTarget2 = printTarget2 + digitalTarget2;
        var combinedTarget3 = printTarget3 + digitalTarget3;
        var combinedTargetQ = printTargetQ + digitalTargetQ;
        
        component.set("v.combinedTarget1", combinedTarget1);
        component.set("v.combinedTarget2", combinedTarget2);
        component.set("v.combinedTarget3", combinedTarget3);
        //component.set("v.combinedTargetQ", combinedTargetQ);
       
        var digitalOnly1 = (printTarget1 == 0) && (printAchieved1 == 0);
        var digitalOnly2 = (printTarget2 == 0) && (printAchieved2 == 0);
        var digitalOnly3 = (printTarget3 == 0) && (printAchieved3 == 0);
        var digitalOnlyQ = (printTargetQ == 0) && (printAchievedQ == 0);
       
        
        var max = Math.max(digitalTarget1, digitalTarget2, digitalTarget3, combinedTarget1, combinedTarget2, combinedTarget3, digitalAchieved1, digitalAchieved2, digitalAchieved3, combinedAchieved1, combinedAchieved2, combinedAchieved3);
        
        component.set("v.digitalTargetBar1", "height: " + ((digitalTarget1 / max) * height) + "px");
        component.set("v.digitalTargetBar2", "height: " + ((digitalTarget2 / max) * height) + "px");
        component.set("v.digitalTargetBar3", "height: " + ((digitalTarget3 / max) * height) + "px");
        component.set("v.combinedTargetBar1", "height: " + ((combinedTarget1 / max) * height) + "px");
        component.set("v.combinedTargetBar2", "height: " + ((combinedTarget2 / max) * height) + "px");
        component.set("v.combinedTargetBar3", "height: " + ((combinedTarget3 / max) * height) + "px");
        component.set("v.digitalAchievedBar1", "height: " + ((digitalAchieved1 / max) * height) + "px");
        component.set("v.digitalAchievedBar2", "height: " + ((digitalAchieved2 / max) * height) + "px");
        component.set("v.digitalAchievedBar3", "height: " + ((digitalAchieved3 / max) * height) + "px");
        component.set("v.combinedAchievedBar1", "height: " + ((combinedAchieved1 / max) * height) + "px");
        component.set("v.combinedAchievedBar2", "height: " + ((combinedAchieved2 / max) * height) + "px");
        component.set("v.combinedAchievedBar3", "height: " + ((combinedAchieved3 / max) * height) + "px");
       
        var underOverCombinedTargetAmt1 = (printAchieved1 + digitalAchieved1) - (printTarget1 + digitalTarget1);
        var underOverCombinedTargetAmt2 = (printAchieved2 + digitalAchieved2) - (printTarget2 + digitalTarget2);
        var underOverCombinedTargetAmt3 = (printAchieved3 + digitalAchieved3) - (printTarget3 + digitalTarget3);
        var underOverCombinedTargetAmtQ = (printAchievedQ + digitalAchievedQ) - (printTargetQ + digitalTargetQ);
        
        var underOverDigitalTargetAmt1 = (digitalAchieved1) - (digitalTarget1);
        var underOverDigitalTargetAmt2 = (digitalAchieved2) - (digitalTarget2);
        var underOverDigitalTargetAmt3 = (digitalAchieved3) - (digitalTarget3);
        var underOverDigitalTargetAmtQ = (digitalAchievedQ) - (digitalTargetQ);
        
        var underOverCombinedTargetPct1 = (combinedTarget1 > 0) ? combinedAchieved1 / combinedTarget1 : 0;
        var underOverCombinedTargetPct2 = (combinedTarget2 > 0) ? combinedAchieved2 / combinedTarget2 : 0;
        var underOverCombinedTargetPct3 = (combinedTarget3 > 0) ? combinedAchieved3 / combinedTarget3 : 0;
        var underOverCombinedTargetPctQ = (combinedTargetQ > 0) ? combinedAchievedQ / combinedTargetQ : 0;
        
        var underOverDigitalTargetPct1 = (digitalTarget1 > 0) ? digitalAchieved1 / digitalTarget1 : 0;
        var underOverDigitalTargetPct2 = (digitalTarget2 > 0) ? digitalAchieved2 / digitalTarget2 : 0;
        var underOverDigitalTargetPct3 = (digitalTarget3 > 0) ? digitalAchieved3 / digitalTarget3 : 0;
        var underOverDigitalTargetPctQ = (digitalTargetQ > 0) ? digitalAchievedQ / digitalTargetQ : 0;
        
        var targetState1 = (printTarget1 == 0 && digitalTarget1 == 0) ? "ET" : ((printTarget1 == 0 && printAchieved1 > 0) ? "NPT" : ((printTarget1 == 0 && printAchieved1 == 0) ? "DO" : ((underOverCombinedTargetAmt1 < 0) ? "CR" : "TK")));
        var targetState2 = (printTarget2 == 0 && digitalTarget2 == 0) ? "ET" : ((printTarget2 == 0 && printAchieved2 > 0) ? "NPT" : ((printTarget2 == 0 && printAchieved2 == 0) ? "DO" : ((underOverCombinedTargetAmt2 < 0) ? "CR" : "TK")));
        var targetState3 = (printTarget3 == 0 && digitalTarget3 == 0) ? "ET" : ((printTarget3 == 0 && printAchieved3 > 0) ? "NPT" : ((printTarget3 == 0 && printAchieved3 == 0) ? "DO" : ((underOverCombinedTargetAmt3 < 0) ? "CR" : "TK")));
        var targetStateQ = (printTargetQ == 0 && digitalTargetQ == 0) ? "ET" : ((printTargetQ == 0 && printAchievedQ > 0) ? "NPT" : ((printTargetQ == 0 && printAchievedQ == 0) ? "DO" : ((underOverCombinedTargetAmtQ < 0) ? "CR" : "TK")));
        
        component.set("v.targetState1", targetState1);
        component.set("v.targetState2", targetState2);
        component.set("v.targetState3", targetState3);
        component.set("v.targetStateQ", targetStateQ);
        
        component.set("v.underOverCombinedTargetAmt1", underOverCombinedTargetAmt1);
        component.set("v.underOverCombinedTargetAmt2", underOverCombinedTargetAmt2);
        component.set("v.underOverCombinedTargetAmt3", underOverCombinedTargetAmt3);
        component.set("v.underOverCombinedTargetAmtQ", underOverCombinedTargetAmtQ);
        
        component.set("v.underOverDigitalTargetAmt1", underOverDigitalTargetAmt1);
        component.set("v.underOverDigitalTargetAmt2", underOverDigitalTargetAmt2);
        component.set("v.underOverDigitalTargetAmt3", underOverDigitalTargetAmt3);
        component.set("v.underOverDigitalTargetAmtQ", underOverDigitalTargetAmtQ);
        
        component.set("v.underOverCombinedTargetPct1", underOverCombinedTargetPct1);
        component.set("v.underOverCombinedTargetPct2", underOverCombinedTargetPct2);
        component.set("v.underOverCombinedTargetPct3", underOverCombinedTargetPct3);
        component.set("v.underOverCombinedTargetPctQ", underOverCombinedTargetPctQ);
        
        component.set("v.underOverDigitalTargetPct1", underOverDigitalTargetPct1);
        component.set("v.underOverDigitalTargetPct2", underOverDigitalTargetPct2);
        component.set("v.underOverDigitalTargetPct3", underOverDigitalTargetPct3);
        component.set("v.underOverDigitalTargetPctQ", underOverDigitalTargetPctQ);
        
        component.set("v.underOverCombinedTargetPct1Class", (underOverCombinedTargetPct1 >= 1) ? "sides green": "sides red");
        component.set("v.underOverCombinedTargetPct2Class", (underOverCombinedTargetPct2 >= 1) ? "sides green": "sides red");
        component.set("v.underOverCombinedTargetPct3Class", (underOverCombinedTargetPct3 >= 1) ? "sides green": "sides red");
        component.set("v.underOverCombinedTargetPctQClass", (underOverCombinedTargetPctQ >= 1) ? "sides green": "sides red");
        
        component.set("v.underOverDigitalTargetPct1Class", (underOverDigitalTargetPct1 >= 1) ? "sides green": "sides red");
        component.set("v.underOverDigitalTargetPct2Class", (underOverDigitalTargetPct2 >= 1) ? "sides green": "sides red");
        component.set("v.underOverDigitalTargetPct3Class", (underOverDigitalTargetPct3 >= 1) ? "sides green": "sides red");
        component.set("v.underOverDigitalTargetPctQClass", (underOverDigitalTargetPctQ >= 1) ? "sides green": "sides red");
        
        var incentivePct = Number(component.get("v.incentivePercent"));
        
        var combinedIncentivePct = regionalTeam ? 0.8*incentivePct : 0.7*incentivePct;
        var digitalIncentivePct = regionalTeam ? 0.2*incentivePct : (programmaticRole ? 0.25*incentivePct : 0.3*incentivePct);
        var programmaticIncentivePct = programmaticRole ? 0.05*incentivePct : 0;
        
        component.set("v.combinedIncentivePercent", combinedIncentivePct);
		component.set("v.digitalIncentivePercent", digitalIncentivePct);
        component.set("v.programmaticIncentivePercent", programmaticIncentivePct);
        
        var combinedPayPct1 = quarterlyRole ? 0 : ((underOverCombinedTargetAmt1 >= 0) ? combinedIncentivePct : 0);
        var combinedPayPct2 = quarterlyRole ? 0 : ((underOverCombinedTargetAmt2 >= 0) ? combinedIncentivePct : 0);
        var combinedPayPct3 = quarterlyRole ? 0 : ((underOverCombinedTargetAmt3 >= 0) ? combinedIncentivePct : 0);
        
        var digitalPayPct1 = quarterlyRole ? 0 : ((underOverDigitalTargetPct1 >= 1) ? digitalIncentivePct : 0);
        var digitalPayPct2 = quarterlyRole ? 0 : ((underOverDigitalTargetPct2 >= 1) ? digitalIncentivePct : 0);
        var digitalPayPct3 = quarterlyRole ? 0 : ((underOverDigitalTargetPct3 >= 1) ? digitalIncentivePct : 0);
        
        var programmaticPayPct1 = quarterlyRole ? 0 : (programmatic1 ? programmaticIncentivePct : 0);
        var programmaticPayPct2 = quarterlyRole ? 0 : (programmatic2 ? programmaticIncentivePct : 0);
        var programmaticPayPct3 = quarterlyRole ? 0 : (programmatic3 ? programmaticIncentivePct : 0);
        
        component.set("v.combinedIncentivePercent1", combinedPayPct1);
		component.set("v.combinedIncentivePercent2", combinedPayPct2);
        component.set("v.combinedIncentivePercent3", combinedPayPct3);
        
		component.set("v.digitalIncentivePercent1", digitalPayPct1);
        component.set("v.digitalIncentivePercent2", digitalPayPct2);
		component.set("v.digitalIncentivePercent3", digitalPayPct3);
        
        component.set("v.programmaticIncentivePercent1", programmaticPayPct1);
        component.set("v.programmaticIncentivePercent2", programmaticPayPct2);
		component.set("v.programmaticIncentivePercent3", programmaticPayPct3);
        
        var salary1 = Number(component.get("v.baseSalary1"));
        var salary2 = Number(component.get("v.baseSalary2"));
        var salary3 = Number(component.get("v.baseSalary3"));
        
        var monthly1 = salary1 / 12;
        var monthly2 = salary2 / 12;
        var monthly3 = salary3 / 12;
        
        component.set("v.monthSalary1", monthly1);
        component.set("v.monthSalary2", monthly2);
        component.set("v.monthSalary3", monthly3);
        
        var combinedPay1 = (combinedPayPct1 * monthly1); //(underOverCombinedTargetPct1 >= 1) ? (combinedPayPct1 * monthly1) : 0;
        var combinedPay2 = (combinedPayPct2 * monthly2); //(underOverCombinedTargetPct2 >= 1) ? (combinedPayPct2 * monthly2) : 0;
        var combinedPay3 = (combinedPayPct3 * monthly3); //(underOverCombinedTargetPct3 >= 1) ? (combinedPayPct3 * monthly3) : 0;
        
        component.set("v.combinedPay1", combinedPay1);
        component.set("v.combinedPay2", combinedPay2);
        component.set("v.combinedPay3", combinedPay3);
        
        var digitalPay1 = (digitalPayPct1 * monthly1); //(underOverDigitalTargetPct1 >= 1) ? (digitalPayPct1 * monthly1) : 0;
        var digitalPay2 = (digitalPayPct2 * monthly2); //(underOverDigitalTargetPct2 >= 1) ? (digitalPayPct2 * monthly2) : 0;
        var digitalPay3 = (digitalPayPct3 * monthly3); //(underOverDigitalTargetPct3 >= 1) ? (digitalPayPct3 * monthly3) : 0;
        
        component.set("v.digitalPay1", digitalPay1);
        component.set("v.digitalPay2", digitalPay2);
        component.set("v.digitalPay3", digitalPay3);
        
        var programmaticPay1 = (programmaticPayPct1 * monthly1); //(underOverDigitalTargetPct1 >= 1) ? (digitalPayPct1 * monthly1) : 0;
        var programmaticPay2 = (programmaticPayPct2 * monthly2); //(underOverDigitalTargetPct2 >= 1) ? (digitalPayPct2 * monthly2) : 0;
        var programmaticPay3 = (programmaticPayPct3 * monthly3); //(underOverDigitalTargetPct3 >= 1) ? (digitalPayPct3 * monthly3) : 0;
        
        component.set("v.programmaticPay1", programmaticPay1);
        component.set("v.programmaticPay2", programmaticPay2);
        component.set("v.programmaticPay3", programmaticPay3);
        
        var monthlyPay1 = quarterlyRole ? 0 : (combinedPay1 + digitalPay1 + programmaticPay1);
        var monthlyPay2 = quarterlyRole ? 0 : (combinedPay2 + digitalPay2 + programmaticPay2);
        var monthlyPay3 = quarterlyRole ? 0 : (combinedPay3 + digitalPay3 + programmaticPay3);
        var monthlyPayQ = quarterlyRole ?
                          (
                            ((underOverCombinedTargetPctQ >= 1) ? ((monthly1 + monthly2 + monthly3) * combinedIncentivePct) : 0) + 
                            ((underOverDigitalTargetPctQ >= 1) ? ((monthly1 + monthly2 + monthly3) * digitalIncentivePct) : 0) + 
                            (programmaticQ ? ((monthly1 + monthly2 + monthly3) * programmaticIncentivePct) : 0)
                          ) :
            			  (monthlyPay1 + monthlyPay2 + monthlyPay3);
        
        component.set("v.monthPay1", monthlyPay1);
        component.set("v.monthPay2", monthlyPay2);
        component.set("v.monthPay3", monthlyPay3);
        component.set("v.monthPayQ", monthlyPayQ);
        
        component.set("v.monthPay1Class", (monthlyPay1 > 0) ? "border green" : "border");
        component.set("v.monthPay2Class", (monthlyPay2 > 0) ? "border green" : "border");
        component.set("v.monthPay3Class", (monthlyPay3 > 0) ? "border green" : "border");
        component.set("v.monthPayQClass", (monthlyPayQ > 0) ? "border green" : "border");
        
        //var qtrCombinedAchieved1 = ((underOverCombinedTargetPct1 >= 0) && (printTarget1 > 0) && (printTarget2 > 0) && (printTarget3 > 0)) ? (monthly1 * combinedIncentivePct) - (monthly1 * combinedPayPct1) : 0;
        //var qtrCombinedAchieved2 = ((underOverCombinedTargetPct2 >= 0) && (printTarget1 > 0) && (printTarget2 > 0) && (printTarget3 > 0)) ? (monthly2 * combinedIncentivePct) - (monthly2 * combinedPayPct1) : 0;
        //var qtrCombinedAchieved3 = ((underOverCombinedTargetPct3 >= 0) && (printTarget1 > 0) && (printTarget2 > 0) && (printTarget3 > 0)) ? (monthly3 * combinedIncentivePct) - (monthly3 * combinedPayPct1) : 0;
        //var qtrCombinedAchievedQ = qtrCombinedAchieved1 + qtrCombinedAchieved2 + qtrCombinedAchieved3;
        
        var qtrCombinedAchieved1 = quarterlyRole? 0 : ((underOverCombinedTargetPctQ >= 1) && (printTarget1 > 0) && (printTarget2 > 0) && (printTarget3 > 0)) ? ((monthly1 * combinedIncentivePct) - (monthly1 * combinedPayPct1)) : 0; //((underOverCombinedTargetPctQ >= 1) && (combinedPay1 == 0)) ? (monthly1 * combinedIncentivePct) : 0;
        var qtrCombinedAchieved2 = quarterlyRole? 0 : ((underOverCombinedTargetPctQ >= 1) && (printTarget1 > 0) && (printTarget2 > 0) && (printTarget3 > 0)) ? ((monthly2 * combinedIncentivePct) - (monthly2 * combinedPayPct2)) : 0;
        var qtrCombinedAchieved3 = quarterlyRole? 0 : ((underOverCombinedTargetPctQ >= 1) && (printTarget1 > 0) && (printTarget2 > 0) && (printTarget3 > 0)) ? ((monthly3 * combinedIncentivePct) - (monthly3 * combinedPayPct3)) : 0;
        var qtrCombinedAchievedQ = qtrCombinedAchieved1 + qtrCombinedAchieved2 + qtrCombinedAchieved3;
        
        component.set("v.qtrCombinedAchieved1", qtrCombinedAchieved1);
        component.set("v.qtrCombinedAchieved2", qtrCombinedAchieved2);
        component.set("v.qtrCombinedAchieved3", qtrCombinedAchieved3);
        component.set("v.qtrCombinedAchievedQ", qtrCombinedAchievedQ);
        
        //var qtrDigitalAchieved1 = ((underOverCombinedTargetPctQ >= 1) && (combinedPay1 == 0)) ? (monthly1 * combinedIncentivePct) : 0;
        //var qtrDigitalAchieved2 = ((underOverCombinedTargetPctQ >= 1) && (combinedPay2 == 0)) ? (monthly2 * combinedIncentivePct) : 0;
        //var qtrDigitalAchieved3 = ((underOverCombinedTargetPctQ >= 1) && (combinedPay3 == 0)) ? (monthly3 * combinedIncentivePct) : 0;
        //var qtrDigitalAchievedQ = qtrDigitalAchieved1 + qtrDigitalAchieved2 + qtrDigitalAchieved3;
        
      //var qtrDigitalAchieved1 = ((underOverDigitalTargetPctQ>=1) && (digitalTarget1>0) && (digitalTarget2>0) && (digitalTarget3>0)) ? (digitalOnly1 ? ((monthly1*incentivePct) - monthly1*(combinedPayPct1 + digitalPayPct1))) : ((monthly1*digitalIncentivePct) - (monthly1*digitalPayPct1)) : 0;
      //var qtrDigitalAchieved2 = ((underOverDigitalTargetPctQ>=1) && (digitalTarget1>0) && (digitalTarget2>0) && (digitalTarget3>0)) ? (digitalOnly2 ? ((monthly2*incentivePct) - monthly2*(combinedPayPct2 + digitalPayPct2))) : ((monthly2*digitalIncentivePct) - (monthly2*digitalPayPct2)) : 0;
      //var qtrDigitalAchieved3 = ((underOverDigitalTargetPctQ>=1) && (digitalTarget1>0) && (digitalTarget2>0) && (digitalTarget3>0)) ? (digitalOnly3 ? ((monthly3*incentivePct) - monthly3*(combinedPayPct3 + digitalPayPct3))) : ((monthly3*digitalIncentivePct) - (monthly3*digitalPayPct3)) : 0;
        
        var qtrDigitalAchieved1 = quarterlyRole? 0 : ((underOverDigitalTargetPctQ>=1) && (digitalTarget1>0) && (digitalTarget2>0) && (digitalTarget3>0)) ? (digitalOnly1 ? ((monthly1*incentivePct) - monthly1*(combinedPayPct1 + digitalPayPct1)) : ((monthly1*digitalIncentivePct) - (monthly1*digitalPayPct1))) : 0;
        var qtrDigitalAchieved2 = quarterlyRole? 0 : ((underOverDigitalTargetPctQ>=1) && (digitalTarget1>0) && (digitalTarget2>0) && (digitalTarget3>0)) ? (digitalOnly2 ? ((monthly2*incentivePct) - monthly2*(combinedPayPct2 + digitalPayPct2)) : ((monthly2*digitalIncentivePct) - (monthly2*digitalPayPct2))) : 0;
        var qtrDigitalAchieved3 = quarterlyRole? 0 : ((underOverDigitalTargetPctQ>=1) && (digitalTarget1>0) && (digitalTarget2>0) && (digitalTarget3>0)) ? (digitalOnly3 ? ((monthly3*incentivePct) - monthly3*(combinedPayPct3 + digitalPayPct3)) : ((monthly3*digitalIncentivePct) - (monthly3*digitalPayPct3))) : 0;
        var qtrDigitalAchievedQ = qtrDigitalAchieved1 + qtrDigitalAchieved2 + qtrDigitalAchieved3;
        
        component.set("v.qtrDigitalAchieved1", qtrDigitalAchieved1);
        component.set("v.qtrDigitalAchieved2", qtrDigitalAchieved2);
        component.set("v.qtrDigitalAchieved3", qtrDigitalAchieved3);
        component.set("v.qtrDigitalAchievedQ", qtrDigitalAchievedQ);
        
        var qtrProgrammaticAchieved1 = quarterlyRole? 0 : (programmaticQ ? (monthly1 * programmaticIncentivePct) - (monthly1 * programmaticPayPct1) : 0);
        var qtrProgrammaticAchieved2 = quarterlyRole? 0 : (programmaticQ ? (monthly2 * programmaticIncentivePct) - (monthly2 * programmaticPayPct2) : 0);
        var qtrProgrammaticAchieved3 = quarterlyRole? 0 : (programmaticQ ? (monthly3 * programmaticIncentivePct) - (monthly3 * programmaticPayPct3) : 0);
        var qtrProgrammaticAchievedQ = qtrProgrammaticAchieved1 + qtrProgrammaticAchieved2 + qtrProgrammaticAchieved3;
        
        component.set("v.qtrProgrammaticAchieved1", qtrProgrammaticAchieved1);
        component.set("v.qtrProgrammaticAchieved2", qtrProgrammaticAchieved2);
        component.set("v.qtrProgrammaticAchieved3", qtrProgrammaticAchieved3);
        component.set("v.qtrProgrammaticAchievedQ", qtrProgrammaticAchievedQ);
        
        component.set("v.qtrCombinedAchieved1Class", (qtrCombinedAchieved1 > 0) ? "green border" : "border");
        component.set("v.qtrCombinedAchieved2Class", (qtrCombinedAchieved2 > 0) ? "green border" : "border");
        component.set("v.qtrCombinedAchieved3Class", (qtrCombinedAchieved3 > 0) ? "green border" : "border");
        component.set("v.qtrCombinedAchievedQClass", (qtrCombinedAchievedQ > 0) ? "green border" : "border");
        component.set("v.qtrDigitalAchieved1Class", (qtrDigitalAchieved1 > 0) ? "green border" : "border");
        component.set("v.qtrDigitalAchieved2Class", (qtrDigitalAchieved2 > 0) ? "green border" : "border");
        component.set("v.qtrDigitalAchieved3Class", (qtrDigitalAchieved3 > 0) ? "green border" : "border");
        component.set("v.qtrDigitalAchievedQClass", (qtrDigitalAchievedQ > 0) ? "green border" : "border");
        component.set("v.qtrProgrammaticAchieved1Class", (qtrProgrammaticAchieved1 > 0) ? "green border" : "border");
        component.set("v.qtrProgrammaticAchieved2Class", (qtrProgrammaticAchieved2 > 0) ? "green border" : "border");
        component.set("v.qtrProgrammaticAchieved3Class", (qtrProgrammaticAchieved3 > 0) ? "green border" : "border");
        component.set("v.qtrProgrammaticAchievedQClass", (qtrProgrammaticAchievedQ > 0) ? "green border" : "border");
        
        var totalA = monthlyPayQ + qtrCombinedAchievedQ + qtrDigitalAchievedQ + qtrProgrammaticAchievedQ;
        
        component.set("v.totalA", totalA);
        
        var totalMonthlyPay = quarterlyRole ? 0 : totalA;
        
        component.set("v.totalMonthlyPay", totalMonthlyPay);
        
		var baseSalaryPerQ = monthly1 + monthly2 + monthly3;   
        
        component.set("v.baseSalaryPerQ", baseSalaryPerQ);
        
        var qtrAccelGateway = (underOverCombinedTargetPctQ < 0.9) ? 0 : underOverCombinedTargetPctQ;
        var incentivePctBaseSalary = 0;
        
        var lookupTable = helper.lookupTable();
        
        for (var i = 0; i < lookupTable.length; i++) {
            if (lookupTable[i].lookup <= qtrAccelGateway) {
                incentivePctBaseSalary = lookupTable[i].value;
            }
        }
        
        component.set("v.qtrAccelGateway", qtrAccelGateway);
        component.set("v.incentivePctBaseSalary", incentivePctBaseSalary);
        
        var totalB = 0;
        
        if (((printTarget3 = 0) && (digitalTarget3 = 0)) || (underOverCombinedTargetPctQ < 1)) {
            totalB = 0;
        } else if ((printTarget1 = 0) && (digitalTarget1 = 0)) {
            totalB = baseSalaryPerQ * (incentivePctBaseSalary - 0.3);
        } else if ((printTarget2 = 0) && (digitalTarget2 = 0)) {
            totalB = baseSalaryPerQ * (incentivePctBaseSalary - 0.3);
        } else if ((incentivePctBaseSalary * baseSalaryPerQ) < totalA) {
            totalB = 0;
        } else {
            totalB = (incentivePctBaseSalary * baseSalaryPerQ) - (baseSalaryPerQ * 0.3);
        }
        
        component.set("v.totalB", totalB);
        
        var financialMonthlyPay = quarterlyRole ? 0 : totalA;
        
        component.set("v.financialMonthlyPay", financialMonthlyPay);
        
        var totalQuarterPay = quarterlyRole ? (monthlyPayQ + totalB) : (totalA + totalB);
        
        component.set("v.totalQuarterPay", totalQuarterPay);
        
        var totalFinalPayQ = quarterlyRole ? totalQuarterPay : (qtrCombinedAchievedQ + qtrDigitalAchievedQ + qtrProgrammaticAchievedQ + monthlyPay3 + totalB);
        
        component.set("v.totalFinalPayQ", totalFinalPayQ);
    }
})