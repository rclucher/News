'use strict';

var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

function openNav() {
	document.getElementById("mySidenav").style.width = "840px";
}

function closeNav() {
	document.getElementById("mySidenav").style.width = "0";
}

function showOnlyThisContainer(ContainerId) {
	jQuery('.tableContainer').hide();
	jQuery(ContainerId).show();
}

require(['./src/cs-full'], function (CS) {
	var ROOT_REFERENCE = '';
	var emptyPromise = Promise.resolve();
	var rulesFunction = undefined;
	var lookupPromise = Promise.resolve();
	var numberOfAddOns = 0;
	var configAttrCache = {};
	var priceItemAttrCache = {};
	var onChangeHandlers = {};
	var handlersBound = false;
	var lookupDeletePollerInterval;
	var rateCards = {};
	var rateCardLines = {};
	var selectedRateCard;
	var rateCardJSON = {};
	var editMode = false;
	var configContainerSelector = '#configurationContainer';
	var processingModel = false;
	var scope;
	var continiueProcessing = false;

	var QUANTITY_ATTR_NAME = 'CS_Quantity';
	var ADD_ON_ASSOC_ATTR_NAME = 'CS_AddOnAssociation';
	var ADD_ON_ATTR_NAME = 'CS_AddOn';

	function buildCompatibilityFunctions() {

		function runCompatibilityFunctionsModel2(ref) {
			var reference = ref || ROOT_REFERENCE;
			var priceItemAttr = findPriceItemAttributeForConfigRef(reference);
			registerOnChangeHandler(priceItemAttr.reference, priceItemOnChangeHandler);

			if (!handlersBound) {
				CS.binding.on('beforeupdate', beforeUpdateHandler);
				CS.binding.on('afterupdate', afterUpdateHandler);
				handlersBound = true;
			}

			processingModel = true;
			if ((typeof angular === "undefined" ? "undefined" : _typeof(angular)) === 'object') {
				scope = angular.element('[ng-controller="mediaConfiguratorCtrl"]').scope();
				if (scope) {
					console.info('EAPI Compatibility starting displayBusyIndicator checks');
					setTimeout(displayBusyIndicator, 50);
				}
			}

			return addDefaultAddOns(reference).catch(function (e) {
				console.error('EAPI Compatibility: error adding default Add Ons', e);
			}).then(function () {
				setConfigurationNames();
				setPrices();
				setLineItemDescriptions();
				displayButtons();
				if(!continiueProcessing){
					processingModel = false;
				}
			}).catch(function (e) {
				console.error('EAPI Compatibility: error running compatibility functions', e);
				processingModel = false;
			});
		}

		function displayBusyIndicator() {
			if (scope) {
				scope.$evalAsync(function () {
					return scope.runningRules = processingModel;
				});
				if (processingModel) {
					setTimeout(displayBusyIndicator, 50);
				} else {
					console.info('EAPI Compatibility ending displayBusyIndicator checks');
				}
			}
		}

		function addDefaultAddOns(configRef) {

			function chainAddDefaultAddons(promise, attr) {
				return promise.then(function () {
					return addDefaultAddOnsForAttribute(attr);
				});
			}

			return getPriceItemForConfig(configRef).then(function (priceItem) {
				if (!priceItem) {
					console.info('EAPI compatibility: Skipping addDefaultAddOns – no Price Item selected');
					return emptyPromise;
				}

				if (productIsNewlyAddedToBasket(configRef)) {
					console.log('EAPI compatibility: adding default Add Ons');
					return findAddOnRelatedProductAttributes(configRef, priceItem);
				} else {
					console.info('Skipping addDefaultAddOns – first run complete');
					return emptyPromise;
				}
			}).then(function (attrList) {
				return _.reduce(attrList, chainAddDefaultAddons, emptyPromise);
			});
		}

		function displayRateCardWidget(configRef, containerSelector) {

			var selector = containerSelector || '.rtWidget';
			return getPriceItemForConfig(configRef).then(function (priceItem) {
				var rateCardAttrs = getRateCardAttribute(configRef);

				if (!rateCardAttrs || !priceItem) {
					console.info('Sipping feature functionality');
					return emptyPromise;
				}
				var rcId = CS.getAttributeValue(rateCardAttrs[0].reference);
				if (rcId && rcId != '') {
					selectedRateCard = rcId;
				}
				return buildRateCardWidget(rateCardAttrs, selector);
			});
		}

		function buildRateCardWidget(rateCardAttrs, selector) {
			var table = '' + '<select required id="rateCardSelect">' + '<option ';
			if (!selectedRateCard || '' == selectedRateCard) {
				table = table + 'selected ';
			}
			table = table + ' value="">Select Rate Card</option>';
			var rclatts = getRateCardLineAttribute(CS.Service.getCurrentConfigRef());
			var tmpRCJSON = CS.getAttributeValue(rclatts[0].reference);
			if (tmpRCJSON && tmpRCJSON != '') {

				var tmpRC = JSON.parse(tmpRCJSON);
				rateCards[tmpRC.rateCard.cspmb__rate_card__r.id] = tmpRC.rateCard;
				_.each(tmpRC.rateCardLines, function (it) {
					rateCardLines[it.id] = it;
				});
				table += '<option ';
				if (selectedRateCard && tmpRC.rateCard.cspmb__rate_card__r.id == selectedRateCard) {
					table = table + ' selected ';
				}
				table = table + ' value="' + tmpRC.rateCard.cspmb__rate_card__r.id + '"' + '>' + tmpRC.rateCard.cspmb__rate_card__r.name + ' </option>';
			}
			table = table + '</select>';
			table = jQuery(table);
			return _.reduce(rateCardAttrs, buildRateCardWidgetSection, Promise.resolve(table)).then(function (table) {
				jQuery(selector).html(table);
				jQuery('#rateCardSelect').change(function (item) {
					buildRateCardLineWidget(item.currentTarget.value);
				});
				if (selectedRateCard && selectedRateCard != '') {
					var table = '<br><br>' + '<table id="rclTable" class="list" style="background: #fff; border-collapse: collapse; width: 100%" >' + '<tr class="headerRow">' + '<th style="padding-right: 6px; padding-top: 8px">Name</th>' + '<th style="padding-right: 6px; padding-top: 8px">Unit</th>' + '<th style="padding-right: 6px; padding-top: 8px">Peak</th>' + '<th style="padding-right: 6px; padding-top: 8px">Off-Peak</th>' + '<th style="padding-right: 6px; padding-top: 8px">Weekend</th>' + '</tr>' + '</table>';
					table = jQuery(table);
					var rateCardLineAttrs = getRateCardLineAttribute(CS.Service.getCurrentConfigRef());

					return _.reduce(rateCardLineAttrs, buildRateCardLineWidgetSection, Promise.resolve(table)).then(function (table) {
						jQuery('#rclTable').html('');
						jQuery('#rateCardSelect').after(table);
						var buttonHtml = '';
						if (!(!selectedRateCard || '' == selectedRateCard) && selectedRateCard.indexOf('clone') == -1) {
							buttonHtml += '<button style="right:5;" class="btn rcbuttons" onClick="CS.EAPI.cloneAndSelectRateCard()">Clone</button>';
						} else if (!(!selectedRateCard || '' == selectedRateCard) && selectedRateCard.indexOf('clone') != -1 && !editMode) {
							buttonHtml += '<button style="right:5;" class="btn rcbuttons" onClick="CS.EAPI.editRateCard()">Edit</button>';
						} else if (editMode) {
							buttonHtml += '<button style="right:5;" class="btn rcbuttons" onClick="CS.EAPI.saveRateCard()">Save</button>';
						}
						jQuery('.rcbuttons').remove();
						jQuery('#rclTable').after(buttonHtml);
					});
				} else {
					return emptyPromise;
				}
			}).catch(function (err) {
				console.error('cannot display rate card widget.', err);
				return Promise.reject(err);
			});
		}

		function buildRateCardWidgetSection(promise, attr) {
			return promise.then(function (table) {
				return getAddOnAssociationsListForAttr(attr).then(function (addOns) {
					_.each(addOns, function (it) {
						rateCards[it.cspmb__rate_card__r.id] = it;
						var row = '' + '<option ';
						if (selectedRateCard && it.cspmb__rate_card__r.id == selectedRateCard) {
							row = row + 'selected ';
						}
						row = row + 'value="' + it.cspmb__rate_card__r.id + '">' + it.cspmb__rate_card__r.name + '</option>';
						table.append(row);
					});
					return table;
				});
			});
		}

		function buildRateCardLineWidget(ref) {
			selectedRateCard = ref;
			var rateCardAttrs = getRateCardAttribute(CS.Service.getCurrentConfigRef());
			CS.setAttribute(rateCardAttrs[0].reference, ref);
		}

		function getRateCardJSON() {
			var rateCardAttrs = getRateCardAttribute(CS.Service.getCurrentConfigRef());
			var rateCardId = CS.getAttributeValue(rateCardAttrs[0].reference);
			var retVal = {};
			if (rateCards.hasOwnProperty(rateCardId)) {
				retVal.rateCard = rateCards[rateCardId];
				var tmpRateCardLines = _.filter(_.values(rateCardLines), function (it) {
					return it.cspmb__rate_card__c == rateCardId;
				});
				retVal.rateCardLines = tmpRateCardLines;
			}
			return retVal;
		}

		function cloneRateCard(rateCardId) {
			var rateCard = getRateCardJSON();
			if (!_.isEmpty(rateCard)) {
				var clonedRateCard = _.clone(rateCard);
				clonedRateCard.rateCard.id = clonedRateCard.rateCard.id + 'clone';
				clonedRateCard.rateCard.cspmb__rate_card__c = clonedRateCard.rateCard.cspmb__rate_card__c + 'clone';
				clonedRateCard.rateCard.cspmb__rate_card__r.id = clonedRateCard.rateCard.cspmb__rate_card__r.id + 'clone';
				clonedRateCard.rateCard.cspmb__rate_card__r.name = clonedRateCard.rateCard.cspmb__rate_card__r.name + ' Clone';
				var tmpRateCardLines = _.map(clonedRateCard.rateCardLines, function (it) {
					it.id = it.id + 'clone';
					it.cspmb__rate_card__c = it.cspmb__rate_card__c + 'clone';
					return it;
				});
				clonedRateCard.rateCardLines = tmpRateCardLines;
				return clonedRateCard;
			} else {
				return {};
			}
		}

		function cloneAndSelectRateCard() {
			var clonedRateCard = cloneRateCard(selectedRateCard);
			var rateCardAttrs = getRateCardAttribute(CS.Service.getCurrentConfigRef());
			var rateCardLineAttrs = getRateCardLineAttribute(CS.Service.getCurrentConfigRef());
			CS.setAttribute(rateCardLineAttrs[0].reference, JSON.stringify(clonedRateCard));
			CS.setAttribute(rateCardAttrs[0].reference, clonedRateCard.rateCard.cspmb__rate_card__r.id);
			selectedRateCard = clonedRateCard.rateCard.cspmb__rate_card__r.id;
		}

		function buildRateCardLineWidgetSection(promise, attr) {
			return promise.then(function (table) {
				if (selectedRateCard.indexOf('clone') == -1) {
					return getAddOnAssociationsListForAttr(attr).then(function (addOns) {
						_.each(addOns, function (it) {
							rateCardLines[it.id] = it;
							var row = '' + '<tr>' + '<td style="padding: 6px;">' + it.name + '</td>' + '<td style="padding: 6px;">' + it.cspmb__rate_card_line_unit__c + '</td>' + '<td style="padding: 6px;">' + it.cspmb__peak__c + '</td>' + '<td style="padding: 6px;">' + it.cspmb__off_peak__c + '</td>' + '<td style="padding: 6px;">' + it.cspmb__weekend__c + '</td>' + '</tr>';
							table.append(row);
						});
						return table;
					});
				} else {
					var tmpRC = getRateCardJSON();
					_.each(tmpRC.rateCardLines, function (it) {
						var row = '' + '<tr>' + '<td style="padding: 6px;">' + it.name + '</td>' + '<td style="padding: 6px;">' + it.cspmb__rate_card_line_unit__c + '</td>';
						if (editMode) {
							row += '<td style="padding: 6px;">' + '<input id="' + it.id + 'pk" type="text" value="' + it.cspmb__peak__c + '" />' + '</td>';
						} else {
							row += '<td style="padding: 6px;">' + it.cspmb__peak__c + '</td>';
						}
						if (editMode) {
							row += '<td style="padding: 6px;">' + '<input id="' + it.id + 'opk" type="text" value="' + it.cspmb__off_peak__c + '" />' + '</td>';
						} else {
							row += '<td style="padding: 6px;">' + it.cspmb__off_peak__c + '</td>';
						}
						if (editMode) {
							row += '<td style="padding: 6px;">' + '<input id="' + it.id + 'wknd" type="text" value="' + it.cspmb__weekend__c + '" />' + '</td>';
						} else {
							row += '<td style="padding: 6px;">' + it.cspmb__weekend__c + '</td>';
						}

						row += '</tr>';
						table.append(row);
					});
					return table;
				}
			});
		}

		function editRateCard() {
			editMode = true;
			CS.EAPI.displayRateCardWidget(CS.Service.getCurrentConfigRef());
		}

		function saveRateCard() {
			editMode = false;
			var rclatts = getRateCardLineAttribute(CS.Service.getCurrentConfigRef());
			var tmpRCJSON = CS.getAttributeValue(rclatts[0].reference);
			var tmpRC = JSON.parse(tmpRCJSON);
			rateCards[tmpRC.rateCard.cspmb__rate_card__r.id] = tmpRC.rateCard;
			_.each(tmpRC.rateCardLines, function (it) {
				var wknd = CS.EAPI.findLastInputElementValue(it.id + 'wknd');
				it.cspmb__weekend__c = wknd;
				var pk = CS.EAPI.findLastInputElementValue(it.id + 'pk');
				it.cspmb__peak__c = pk;
				var opk = CS.EAPI.findLastInputElementValue(it.id + 'opk');
				it.cspmb__off_peak__c = opk;
				rateCardLines[it.id] = it;
				tmpRC.rateCardLines[it.id] = it;
			});
			CS.setAttribute(rclatts[0].reference, JSON.stringify(tmpRC));
			CS.EAPI.displayRateCardWidget(CS.Service.getCurrentConfigRef());
		}

		function displayFeatureWidget(configRef, containerSelector) {

			var selector = containerSelector || '.ftWidget';
			return getPriceItemForConfig(configRef).then(function (priceItem) {
				var featureAttrs = getFeatureAttribute(configRef);
				if (!featureAttrs || !priceItem) {
					console.info('Sipping feature functionality');
					return emptyPromise;
				}
				return buildFeatureWidget(featureAttrs, selector);
			});
		}

		function buildFeatureWidget(featureAttrs, selector) {
			var table = '' + '<table class="list" style="background: #fff; border-collapse: collapse; width: 100%" >' + '<tr class="headerRow">' + '<th style="padding-right: 6px; padding-top: 8px">Name</th>' + '<th style="padding-right: 6px; padding-top: 8px">Description</th>' + '</tr>' + '</table>';
			table = jQuery(table);
			return _.reduce(featureAttrs, buildFeatureWidgetSection, Promise.resolve(table)).then(function (table) {
				jQuery(selector).html(table);
			}).catch(function (err) {
				console.error('cannot display feature widget.', err);
				return Promise.reject(err);
			});
		}

		function buildFeatureWidgetSection(promise, attr) {
			return promise.then(function (table) {
				return getAddOnAssociationsListForAttr(attr).then(function (addOns) {
					_.each(addOns, function (it) {
						var row = '<tr>' + '<td style="padding: 6px">' + it.cspmb__feature__r.name + '</td>' + '<td style="padding: 6px">' + it.cspmb__feature__r.cspmb__feature_description__c + '</td>' + '</tr>';
						table.append(row);
					});
					return table;
				});
			});
		}

		function overrideRelatedProductControls(configRef) {
			var relatedProductAttrs;
			return findAddOnRelatedProductAttributes(configRef).then(function (attrs) {
				relatedProductAttrs = attrs;
				hideControlButtons(attrs);
			}).then(function () {
				return getPriceItemForConfig(configRef);
			}).then(function (priceItem) {
				var promises = [];
				if (priceItem) {
					_.each(relatedProductAttrs, function (it) {
						promises.push(overrideControlsForAttr(it));
					});
				}
				return Promise.all(promises);
			}).catch(function (err) {
				console.error('EAPI2 - could not override related product controls', err);
				return Promise.reject(err);
			});
		}

		function overrideControlsForAttr(attr) {
			return getAddOnAssociationsListForAttr(attr).then(function (assocs) {
				var currentlySelectedAddOnIds = getSelectedAddOnAssocIds(attr);
				return buildAddOnListWithGroupAndCardinalityConstraints(attr, assocs, currentlySelectedAddOnIds);
			}).then(function (addOns) {
				_.each(addOns, function (it) {
					if (it.assoc.cspmb__default_quantity__c > 0) {
						for(var i=0; i<it.attr.relatedProducts.length;i++){
							var attributeWraper = CS.Service.config[it.attr.relatedProducts[i].reference + ':CS_AddOnAssociation_0'];
							if(it.assoc.id == attributeWraper.attr.cscfga__Value__c){
								jQuery('[data-cs-ref="' + it.attr.relatedProducts[i].reference + '"][data-cs-action][data-cs-action!="editRelatedProduct"]').css({ display: 'none' });
							}
						}
						
					}
				});
			});
		}

		function displayPricingWidget(configRef, containerSelector) {
			var relatedProductAttrs;
			var selector = containerSelector || '.pmWidget';
			return findAddOnRelatedProductAttributes(configRef).then(function (attrs) {
				relatedProductAttrs = attrs;
				hideControlButtons(attrs);
			}).then(function () {
				return getPriceItemForConfig(configRef);
			}).then(function (priceItem) {
				if (!priceItem) {
					console.info('EAPI compatibility: Clearing displayPricingWidget – no Price Item selected');
					jQuery(selector).html('');
					return emptyPromise;
				}
				return buildPricingWidget(relatedProductAttrs, selector);
			});
		}

		function buildPricingWidget(attrs, selector) {
			var table = '   	<style type="text/css">  ' + '   /* Dropdown Button */  ' + '   .dropbtn {  ' + '       border: none;  ' + '       cursor: pointer;  ' + '   }  ' + '     ' + '   /* Dropdown button on hover & focus */  ' + '     ' + '     ' + '   /* Dropdown Content (Hidden by Default) */  ' + '   .dropdown-content {  ' + '       display: none;  ' + '       position: absolute;  ' + '       background-color: #f9f9f9;  ' + '       min-width: 500px;  ' + '       box-shadow: 0px 8px 16px 0px rgba(0,0,0,0.2);  ' + '       z-index: 1;  ' + '   }  ' + '     ' + '     ' + '   /* Change color of dropdown links on hover */  ' + '   .dropdown-content a:hover {background-color: #f1f1f1}  ' + '     ' + '   /* Show the dropdown menu (use JS to add this class to the .dropdown-content container when the user clicks on the dropdown button) */  ' + '  .show {display:block;}  ' + '  	</style>  ' + '<table class="list" style="background: #fff; border-collapse: collapse; width: 100%" >' + '<div id="myDropdown" class="pbHeader dropdown-content">' + '<tr class="headerRow">' + '<th style="padding-left: 6px; padding-right: 6px; padding-top: 8px">Action</th>'

			+ '<!--th style="padding-right: 6px; padding-top: 8px">Quantity</th-->' + '<th style="padding-right: 6px; padding-top: 8px">Add On</th>' + '<th style="padding-right: 6px; padding-top: 8px">Group</th>' + '<!--th style="padding-right: 6px; padding-top: 8px">One-Off Charge</th-->' + '<!--th style="padding-right: 6px; padding-top: 8px">Recurring Charge</th-->' + '<th style="padding-top: 8px">Message</th>' + '</tr>' + '</div>' + '</table>';
			table = jQuery(table);
			return _.reduce(attrs, buildPricingWidgetSectionForAttr, Promise.resolve(table)).then(function (table) {
				jQuery(selector).html(table);
			}).catch(function (err) {
				console.error('EAPI compatibility: cannot display pricing widget.', err);
				return Promise.reject(err);
			});
		}

		function findLastInputElementValue(addOnAssocId) {
			return jQuery(jQuery('input[id^="' + addOnAssocId + '"]')[jQuery('input[id^="' + addOnAssocId + '"]').length - 1]).val();
		}

		function buildPricingWidgetSectionForAttr(promise, attr) {
			return promise.then(function (table) {
				var headerRow = jQuery('<tr><th style="background: #ddd; padding: 6px" colspan="7">' + (attr.attr.cscfga__Label__c || attr.attr.Name) + '</th></tr>');
				return getAddOnAssociationsListForAttr(attr).then(function (assocs) {
					var currentlySelectedAddOnIds = getSelectedAddOnAssocIds(attr);
					return buildAddOnListWithGroupAndCardinalityConstraints(attr, assocs, currentlySelectedAddOnIds);
				}).then(function (addOns) {
					var optionalAddOns = _.filter(addOns, function (it) {
						return !(it.assoc.cspmb__default_quantity__c > 0);
					});
					if (optionalAddOns.length) {
						table.append(headerRow);
					}
					_.each(optionalAddOns, function (it) {
						var input;
						var quantityjQuery = '';
						var attrValue = 0;
						var isNew = true;
						var productReference;

						if (jQuery('div[data-cs-binding="' + attr.reference + '"] div.slds-truncate:contains("' + it.assoc.cspmb__add_on_price_item__r.name + '")')[0] && it.assoc.add_on_type__c == 'Quantity') {
							isNew = false;
							productReference = jQuery(jQuery('div[data-cs-binding="' + attr.reference + '"] span:contains("' + it.assoc.cspmb__add_on_price_item__r.name + '")')).attr("data-cs-ref");
							attrValue = CS.getAttributeValue(productReference + ':' + QUANTITY_ATTR_NAME + '_0');
						}

						if (it.assoc.add_on_type__c == 'Quantity') {
							input = '<input type="number" value="' + attrValue + '" min="0" id="Quantity' + it.assoc.id + '"></input>';
							quantityjQuery = '\',CS.EAPI.findLastInputElementValue(\'' + 'Quantity' + it.assoc.id + '\')';
						} else {
							input = '<input type="number" value ="1" id="Checkbox' + it.assoc.id + '" readonly></input>';
							quantityjQuery = '\',1';
						}
						var row = '<tr>' + '<td style="padding: 6px;"><a href="#" onclick="CS.EAPI.insertAddOn(\'' + attr.reference + '\',\'' + it.assoc.id + quantityjQuery + ',' + isNew + ',\'' + productReference + '\')">' + (it.isAvailable ? 'Add' : '') + '</a></td>'
						+ '<!--td>' + input + '</td-->' + '<td style="padding: 6px">' + it.assoc.cspmb__add_on_price_item__r.name + '</td>' + '<td style="padding: 6px">' + it.assoc.cspmb__group__c + '</td>' + '<!--td style="text-align: left; padding: 6px">' + asDecimal(it.assoc.cspmb__add_on_price_item__r.cspmb__one_off_charge__c, 2) + '</td-->' + '<!--td style="text-align: left; padding: 6px">' + asDecimal(it.assoc.cspmb__add_on_price_item__r.cspmb__recurring_charge__c, 2) + '</td-->' + '<td style="padding: 6px">' + (it.isAvailable ? '' : it.unavailableReason) + '</td>' + '</tr>';
						table.append(row);
					});
					return table;
				});
			});
		}

		function insertAddOn(attrRef, addOnId, quantity, isNew, productReference) {
			if (isNew) {
				return createRelatedProducts({ reference: attrRef }, [{ id: addOnId }], quantity, isNew).then(function () {
					displayButtons();
					var html = '<div id="pmwgt" class="pmWidget dropdown pbButton CS_configButtons"><button class="dropbtn ppbButton CS_configButtons">Building Widget</button></div>';
					if (jQuery('#pmwgt')[0] == undefined) {
						var ref = CS.Service.getCurrentConfigRef();
						if (ref !== "") {
							ref = ref + '\\:';
						}
					}
					displayPricingWidget(CS.Service.getCurrentConfigRef(), '.pmWidget');
				});
			} else {
				CS.setAttributeValue(productReference + ':' + QUANTITY_ATTR_NAME + '_0', quantity);
				displayButtons();

				var html = '<div id="pmwgt" class="pmWidget dropdown pbButton CS_configButtons"><button class="dropbtn ppbButton CS_configButtons">Building Widget</button></div>';
				if (jQuery('#pmwgt')[0] == undefined) {
					var ref = CS.Service.getCurrentConfigRef();
					if (ref !== "") {
						ref = ref + '\\:';
					}
				}
				displayPricingWidget(CS.Service.getCurrentConfigRef(), '.pmWidget');

				return null;
			}
		}

		function setConfigurationNames() {
			var pricingModelLookups = getPricingModelLookupAttributes();
			var lookups = _.filter(pricingModelLookups, function (it) {
				return !!it.attributeFields.__ConfigName__;
			});
			_.each(lookups, function (it) {
				var ref = CS.Util.getAnchorReference(CS.Util.getParentReference(it.reference));
				var wrapper = CS.getConfigurationWrapper(ref);
				_.each(wrapper.relatedProducts, function (rp) {
					var reference = it.reference.replace(ref, rp.reference);
					var name = resolveLookupValue(it.attributeFields.__ConfigName__.cscfga__Value__c, reference);
					var parent = CS.Util.getParentReference(reference);
					CS.setConfigurationProperty(parent, 'name', name);
					console.log('EAPI compatibility: Set configuration name for \'' + parent + '\' to: ' + name);
				});
				_.each(CS.binding.getBindings(ref), function (binding) {
					binding.handler.updateUI(binding);
				});
			});
		}

		function setPrices() {
			var pricingAttrs = _.filter(CS.Service.config, function (it) {
				return it.attr && it.attributeFields.__Price__;
			});
			_.each(pricingAttrs, function (it) {
				var af = it.attributeFields.__Price__.cscfga__Value__c;
				var lkVal = resolveLookupValue(af, it.reference);
				CS.setAttributeField(it.reference, 'price', lkVal);
				console.log('EAPI compatibility: Set price of ' + it.reference + ' to: ' + lkVal);
				if (lkVal == null) {
					CS.setAttributeField(it.reference, 'islineitem', false);
				}
			});
		}

		function setLineItemDescriptions() {
			var pricingModelLookups = getPricingModelLookupAttributes();
			var lineItems = _.filter(CS.Service.config, function (it) {
				return it.attr && it.attr.cscfga__Is_Line_Item__c;
			});
			_.each(lineItems, function (it) {
				var lkVal = resolveLookupValue(it.definition.cscfga__Line_Item_Description__c, it.reference);
				if (lkVal) {
					CS.getAttributeFieldValue(it.reference, 'lineitemdescription', lkVal);
					console.log('EAPI compatibility: Set line item description for ' + it.reference + ' to: ' + lkVal);
				}
			});
		}

		function addDefaultAddOnsForAttribute(attr) {
			return getAddOnAssociationsListForAttr(attr).then(filterAddOnAssociationsByDefaultQuantity).then(function (addOns) {
				return createRelatedProducts(attr, addOns, 1, true);
			});
		}

		function getAddOnAssociationsListForAttr(attWrapper) {
			var configRef = CS.Util.getParentReference(attWrapper.reference);
			var prefix = configRef ? configRef + ':' : '';
			var regExp = new RegExp('^' + prefix + '[^:]+$');
			var index = CS.Service.getProductIndex('');
			var attrDef = index.all[attWrapper.definitionId];
			var productDefinitionId = CS.getConfigurationWrapper(configRef).config.cscfga__Product_Definition__c;
			var filterAttrNames;
			var filterAttrs = {};

			if (!attrDef) {
				console.warn('Could not find attribute definition id for attr ', attWrapper);
				return Promise.reject('Could not find attribute definition id for attr ' + attWrapper.reference);
			}
			var lc = index.all[attrDef.cscfga__Lookup_Config__c];
			if (!lc) {
				return Promise.reject('LookupConfig could not be found for attr ' + attWrapper.reference);
			}

			var lq = index.all[lc.cscfga__Filter__c];
			if (!lq) {
				return Promise.reject('LookupQuery filter could not be found for attr ' + attWrapper.reference);
			}

			if (lq.cscfga__Referenced_Attributes__c) {
				try {
					filterAttrNames = JSON.parse(lq.cscfga__Referenced_Attributes__c);
				} catch (e) {
					console.error('Could not parse referenced Attributes: ' + lq.Id + ' / ' + lq.cscfga__Referenced_Attributes__c);
				}
			} else {
				filterAttrNames = [];
			}

			_.each(CS.Service.config, function (node) {
				if (node.attr && regExp.exec(node.reference)) {
					var name = node.attr.Name;
					if (_.indexOf(filterAttrNames, name) > -1) {
						var val = node.attr.cscfga__Value__c;
						filterAttrs[name] = val;
					}
				}
			});

			return doLookupQuery(lq.Name, filterAttrs, productDefinitionId);
		}

		function findAddOnRelatedProductAttributes(configRef) {
			function addOnGeneratorLookupsFilter(index, configAttrs) {
				return function (avail) {
					var rpAttrs = index.attributeDefsByProduct[avail.cscfga__Product_Definition__c];
					if (!rpAttrs) {
						console.error('Could not find attribute definitions for product definition: ', avail.cscfga__Product_Definition__c);
					}

					var addOnGenerators = _.filter(_.where(rpAttrs, { cscfga__Type__c: 'Lookup' }), function (it) {
						return _.where(index.attributeFieldDefsByAttributeDef[it.Id], { Name: '__AddonGenerator__' }).length;
					});

					if (addOnGenerators.length) {
						return _.filter(configAttrs, function (it) {
							return it.definitionId === avail.cscfga__Attribute_Definition__c;
						});
					}
				};
			}

			function findAddOnGeneratorLookups(configRef, products, index) {
				var configAttrs = getAttributesForConfigRef(configRef);
				return _.flatten(_.filter(_.map(products, addOnGeneratorLookupsFilter(index, configAttrs)), removeUndefinedFilter));
			}

			function loadProductReducer(promise, avail) {
				var defId = avail.cscfga__Product_Definition__c;
				return !!defId && !CS.Service.getProductIndex(defId) ? promise.then(function () {
					return loadProduct(defId);
				}) : promise;
			}

			function removeUndefinedFilter(it) {
				return !!it;
			}

			var index = CS.Service.getProductIndex('');
			var currentProdDefId = CS.getConfigurationWrapper(configRef).config.cscfga__Product_Definition__c;

			var singleAvailableProducts = _.flatten(_.filter(_.where(index.availableProductsByAttributeDef, { length: 1 }), attributesForProductFilter(currentProdDefId, index)));

			var loadProductsPromise = _.reduce(singleAvailableProducts, loadProductReducer, emptyPromise);

			return loadProductsPromise.then(function () {
				return findAddOnGeneratorLookups(configRef, singleAvailableProducts, index);
			});
		}

		function findPriceItemAttributeForConfigRef(ref) {
			var pi = priceItemAttrCache[ref];
			if (pi) {
				return pi;
			}

			var pis = _.filter(CS.Service.config, function (wrapper, reference) {
				return wrapper.attributeFields && wrapper.attributeFields.__PriceItemReference__ && CS.Util.getParentReference(reference) === ref;
			});

			if (pis.length > 1) {
				console.warn('Multiple __PriceItemReference__ markers found, model is invalid: ', pis);
			}

			priceItemAttrCache[ref] = pis[0];

			return pis[0];
		}

		function getPriceItemForConfig(ref) {
			var piAttr = findPriceItemAttributeForConfigRef(ref);
			if (!piAttr) {
				console.log('EAPI compatibility: No price item attribute found in config ref \'' + ref + '\'');
			}
			var priceItem = CS.getAttributeValue(piAttr.reference);
			if (!priceItem) {
				console.log('EAPI compatibility: No price item found in attribute ref ' + piAttr.reference);
			}
			return Promise.resolve(priceItem);
		}

		function buildAddOnListWithGroupAndCardinalityConstraints(attr, assocs, selectedAddOnAssocIds) {
			var groups = buildAssociationGroups(assocs);
			var groupCounts = getAssociationGroupCounts(assocs, groups, selectedAddOnAssocIds);
			var index = 0;
			return _.map(assocs, function (assoc) {
				var grp = groups[assoc.cspmb__group__c];
				var max = grp[assoc.cspmb__add_on_price_item__c];
				var count = groupCounts[assoc.cspmb__group__c];
				var isAvailable = true;
				var reason;

				if (max > 0 && count + 1 > max) {
					isAvailable = false;
					reason = 'There ' + (count === 1 ? 'is' : 'are') + ' already ' + count + ' of this type of add on selected.';
				}

				return { assoc: assoc, attr: attr, index: index++, isAvailable: isAvailable, unavailableReason: reason };
			});
		}

		function filterAddOnAssociationsByDefaultQuantity(assocs) {
			return _.filter(assocs, function (assoc) {
				return assoc.cspmb__default_quantity__c > 0;
			});
		}


		function doLookupQuery(name, dynamicFilterMap, productDefinitionId) {
			return new Promise(function (resolve, reject) {
				Visualforce.remoting.Manager.invokeAction('cscfga.UISupport.doMultiRowLookupQuery', name, dynamicFilterMap, productDefinitionId, function (result, event) {
					if (event.status) {
						resolve(keysToLowerCase(result));
					} else {
						console.error(event);
						reject(event);
					}
				}, { escape: false });
			});
		}

		function loadLookupRecord(params) {
			lookupPromise = lookupPromise.then(function () {
				return new Promise(function (resolve, reject) {
					Visualforce.remoting.Manager.invokeAction('cscfga.UISupport.loadLookupRecord', params, function (result, event) {
						if (event.status) {
							resolve(result);
						} else {
							console.error(event);
							reject(event);
						}
					}, { escape: false });
				});
			});
			return lookupPromise;
		}


		function attributesForProductFilter(productId, index) {
			return function (it) {
				var attrDef = index.all[it[0].cscfga__Attribute_Definition__c];
				return attrDef && attrDef.cscfga__Product_Definition__c == productId && !!it[0].cscfga__Product_Definition__c;
			};
		}

		function getAddOnAttributes() {
			return _.filter(CS.Service.config, function (it) {
				return it.attributeFields && it.attributeFields.__AddOn__;
			});
		}

		function getFeatureAttribute(configRef) {

			return _.filter(CS.Service.config, function (it) {
				var ref = '';
				var n = it.reference.lastIndexOf(":");
				if (n != -1) {
					ref = it.reference.substr(0, n);
				}
				return it.attributeFields && it.attributeFields.__Feature__ && ref === configRef;
			});
		}

		function getRateCardAttribute(configRef) {
			return _.filter(CS.Service.config, function (it) {
				var ref = '';
				var n = it.reference.lastIndexOf(":");
				if (n != -1) {
					ref = it.reference.substr(0, n);
				}
				return it.attributeFields && it.attributeFields.__RateCard__ && ref === configRef;
			});
		}

		function getRateCardLineAttribute(configRef) {
			return _.filter(CS.Service.config, function (it) {
				var ref = '';
				var n = it.reference.lastIndexOf(":");
				if (n != -1) {
					ref = it.reference.substr(0, n);
				}
				return it.attributeFields && it.attributeFields.__RateCardLine__ && ref === configRef;
			});
		}

		function getAttributesForConfigRef(ref) {
			var prefix = ref ? ref + ':' : '';
			var regExp = new RegExp('^' + prefix + '[^:]+$');
			var cached = configAttrCache[ref];

			if (cached) {
				return cached;
			}

			return configAttrCache[ref] = _.filter(CS.Service.config, function (node) {
				return node.attr && regExp.exec(node.reference);
			});
		}

		function getPricingModelLookupAttributes() {
			var lookupConfigIds = getPricingModelLookupConfigIds();
			var pricingModelLookupAttrs = _.filter(CS.Service.config, function (it) {
				var def = getAttributeDefinition(it);
				return it.attr && _.contains(lookupConfigIds, def.cscfga__Lookup_Config__c);
			});
			return pricingModelLookupAttrs;
		}

		function getPricingModelLookupConfigIds() {
			return _.map(_.filter(CS.Service.getProductIndex().all, function (it) {
				return it.attributes && it.attributes.type === 'cscfga__Lookup_Config__c' && (it.cscfga__Object__c === 'cspmb__price_item__c' || it.cscfga__Object__c === 'cspmb__add_on_price_item__c' || it.cscfga__Object__c === 'cspmb__price_item_add_on_price_item_association__c');
			}), function (it) {
				return it.Id;
			});
		}

		function getPrimaryPricingModelLookupAttribute(pricingModelLookups) {
			if (pricingModelLookups.length == 1) {
				return pricingModelLookups[0];
			}
			return _.find(pricingModelLookups, function (it) {
				!!it.attributeFields.__Primary__;
			});
		}

		function getSelectedAddOnAssocIds(addOnAttr) {
			return _.filter(_.map(addOnAttr.relatedProducts, function (it) {
				return CS.getAttributeValue(makeRef(it.reference, ADD_ON_ASSOC_ATTR_NAME + '_0')); 
			}), function (it) {
				return it != null;
			});
		}

		function hideControlButtons(attrs) {
			_.each(attrs, function (attr) {
				jQuery('[data-cs-control="' + attr.reference + '"][data-cs-type="add"]').css({ display: 'none' });
			});
		}


		function prepareDynamicFilterMap(lookupQueryObj, attrRef) {
			var configPrefix = '';
			attrRef = attrRef || '';
			var n = attrRef.lastIndexOf(":");
			if (n != -1) {
				configPrefix = attrRef.substr(0, n);
			}
			var referencedAttributes = lookupQueryObj ? JSON.parse(lookupQueryObj.cscfga__Referenced_Attributes__c) : [];
			var dynamicFilterMap = {};
			var bConfigAttribute = false;
			var attrRef;

			_.each(CS.Service.config, function (it) {
				if (it.attr) {
					bConfigAttribute = false;
					attrRef = it.reference;
					if (configPrefix !== '' && attrRef.lastIndexOf(configPrefix) != -1) {
						if (attrRef.substring(n).split(":").length < 3) {
							bConfigAttribute = true;
						}
					}
					if (configPrefix === '' && attrRef.lastIndexOf(':') == -1) {
						bConfigAttribute = true;
					}
					if (bConfigAttribute) {
						var name = it.attr.Name;
						if (lookupQueryObj === undefined) {
							dynamicFilterMap[name] = it.attr.cscfga__Value__c;
						} else {
							if (_.indexOf(referencedAttributes, name) !== -1) {
								dynamicFilterMap[name] = it.attr.cscfa__Value__c;
							}
						}
					}
				}
			});
		}

		function resolveLookupValue(exp, ctx) {
			var lk = exp ? exp.match(/\{([^\.]+)\.([^\}]+)\}/) : [];
			if (lk != null && lk.length == 3) {
				var lkName = lk[1];
				var lkField = lk[2];
				var ref = attNameToRef(lkName, CS.Util.getParentReference(ctx));
				if (!ref) {
					console.error('Pricing lookup reference ' + exp + ' could not be resolved.');
					return;
				}
				return CS.getLookupValue(ref, lkField);
			}
		}

		function attNameToRef(name, context) {
			var atts = _.filter(CS.Service.config, function (it) {
				return it.attr && it.attr.Name == name && CS.Util.getParentReference(it.reference) == context;
			});
			if (atts.length == 1) return atts[0].reference;
		}

		function attributeIsPresent(ref) {
			return CS.Service.config[ref] && CS.Service.config[ref].attr;
		}

		function getAttributeDefinition(node) {
			var index = CS.Service.getProductIndex();
			return index.all[node.definitionId];
		}

		function beforeUpdateHandler(ref, properties) {
			var currentValue = CS.getAttributeValue(ref);
			if (properties.value && properties.value != currentValue) {
				properties._oldVal = currentValue;
			}
		}

		function afterUpdateHandler(ref, properties) {
			var currentValue = CS.getAttributeValue(ref);
			if (properties._oldVal !== undefined) {
				attributeHasChanged(ref, properties._oldVal, properties);
			}
		}

		function attributeHasChanged(ref, oldVal, properties) {
			if (onChangeHandlers[ref] && typeof onChangeHandlers[ref].handler === 'function') {
				onChangeHandlers[ref].handler(ref, oldVal, properties);
			}
		}

		function registerOnChangeHandler(ref, handler) {
			if (!lookupDeletePollerInterval) {
				lookupDeletePollerInterval = window.setInterval(checkForDeletedLookupValues, 500);
			}
			var wrapper = CS.getAttributeWrapper(ref);
			if (wrapper) {
				onChangeHandlers[ref] = {
					type: wrapper.definition ? wrapper.definition.cscfga__Type__c : wrapper.displayInfo,
					handler: handler,
					lastValue: wrapper.attr.cscfga__Value__c 
				};
			} else {
				console.warn('Attribute ref ' + ref + ' not found, cannot register onChange handler');
			}
		}

		function checkForDeletedLookupValues() {
			_.each(onChangeHandlers, function (handler, ref) {
				if (handler && handler.type === 'Lookup') {
					if (handler.lastValue) {
						var attVal = CS.getAttributeValue(ref);
						if (attVal !== undefined && attVal !== handler.lastValue) {
							console.info('Lookup attribute cleared: ', ref);
							attributeHasChanged(ref, handler.lastValue, { value: '' });
							handler.lastValue = '';
							var rclatts = getRateCardLineAttribute(CS.Service.getCurrentConfigRef());
							if (rclatts) {
								//CS.setAttribute(rclatts[0].reference, '');
							}
						}
					}
				}
			});
		}

		function priceItemOnChangeHandler(ref, oldVal, properties) {

			if (oldVal && !properties.value || oldVal && properties.value && oldVal != properties.value) {
				var configRef = CS.Util.getParentReference(ref);
				continiueProcessing = true;
				processingModel = true;
				displayBusyIndicator();
				findAddOnRelatedProductAttributes(configRef).then(function (addOnAttrs) {
					_.each(addOnAttrs, function (attr) {
						_.each(attr.relatedProducts, function (rp) {
							CS.Service.removeRelatedProduct(rp.reference);
						});
					});
				}).then(function () {
					var firstRunFlagRef = CS.Util.generateReference('First_Run', { ref: CS.Service.getCurrentConfigRef() });
					if (attributeIsPresent(firstRunFlagRef)) {
						CS.setAttribute(firstRunFlagRef, '');
					}
					addDefaultAddOns(CS.Service.getCurrentConfigRef()).then(function () {	
						processingModel = true;
						displayBusyIndicator();
						CS.Rules.evaluateAllRules();
						displayButtons();
						var html = '<div id="pmwgt" class="pmWidget dropdown pbButton CS_configButtons"><button class="dropbtn ppbButton CS_configButtons">Building Widget</button></div>';
						if (jQuery('#pmwgt')[0] == undefined) {
							ref = CS.Service.getCurrentConfigRef();
							if (ref !== "") {
								ref = ref + '\\:';
							}
							jQuery('[data-cs-binding=' + ref + 'PMWidget_0]').parent().parent().prepend(html);
						}
						displayPricingWidget(CS.Service.getCurrentConfigRef(), '.pmWidget');
					}).then(function(){processingModel = false; continiueProcessing = false;});
				});
			}
			registerOnChangeHandler(ref, priceItemOnChangeHandler);
		}

		function setLookupAttributeValue(attrRef, recordId) {
			var wrapper = CS.getAttributeWrapper(attrRef);
			var index = CS.Service.getProductIndex();
			var def = index.all[wrapper.definitionId];
			var lc = index.all[def.cscfga__Lookup_Config__c];

			var lookupAttribute = {
				'attributeId': wrapper.attr.Id,
				'attributeValue': recordId,
				'attributeDefinitionId': def.Id,
				'attributeLookupConfigId': lc.Id,
				'attributeObjectMappingId': lc.cscfga__Search_Columns__c
			};
			return loadLookupRecord(JSON.stringify(lookupAttribute)).then(function (result) {
				var attKey = lookupAttribute.attributeValue;
				var rec = result[attKey] || {};
				var lookupData = _.extend({}, rec);
				lookupData.columnMap = rec.columnMap;
				CS.lookupRecords[attKey] = lookupData;
				CS.setAttributeValue(attrRef, recordId);
			});
		}

		function buildAssociationGroups(assocs) {
			var groups = {};
			_.each(assocs, function (assoc) {
				var name = assoc.cspmb__group__c;
				var gm = groups[name];
				if (!gm) {
					groups[name] = gm = {};
				}
				gm[assoc.cspmb__add_on_price_item__c] = parseInt(assoc.cspmb__max__c, 16) || 0;
			});
			return groups;
		}

		function getAssociationGroupCounts(assocs, groups, selectedAddOnAssocIds) {
			var groupCounts = {};
			var assocsById = _.object(_.map(assocs, function (assoc) {
				return [assoc.id, assoc];
			}));

			_.each(selectedAddOnAssocIds, function (id) {
				var assoc = assocsById[id];
				if (assoc) {
					var count = groupCounts[assoc.cspmb__group__c] || (groupCounts[assoc.cspmb__group__c] = 0);
					groupCounts[assoc.cspmb__group__c] = count + 1;
				}
			});

			return groupCounts;
		}

		function markProductFirstRunCompleted(configRef) {
			console.log('EAPI compatibility: first run completed for ref ' + configRef);
			CS.setAttributeValue(CS.Util.generateReference('First_Run', { ref: configRef }), 'true');
		}

		function markProductFirstRunNotCompleted(configRef) {
			CS.setAttributeValue(CS.Util.generateReference('First_Run', { ref: configRef }), '');
		}

		function productIsNewlyAddedToBasket(ref) {
			var firstRunFlagRef = CS.Util.generateReference('First_Run', { ref: ref });
			if (attributeIsPresent(firstRunFlagRef)) {
				if (!CS.getAttributeValue(firstRunFlagRef)) {
					CS.setAttributeValue(firstRunFlagRef, 'true');
					return true;
				}
			} else {
				console.warn('EAPI compatibility: Cannot evaluate default add-ons as no first run attribute present');
			}
			return false;
		}

		function blankForNull(val) {
			return val ? val : '';
		}

		function asDecimal(val, scale) {
			var f = parseFloat(val);
			if (isNaN(f)) {
				return '';
			} else {
				return f.toFixed(scale);
			}
		}

		function error(err) {
			console.error(err);
			return Promise.reject(err);
		}

		function keysToLowerCase(obj) {
			var data = _.isArray(obj) ? [] : {};
			_.each(obj, function (val, key) {
				if (key.toLowerCase) {
					key = key.toLowerCase();
				}
				if (val && (typeof val === "undefined" ? "undefined" : _typeof(val)) === 'object') {
					data[key] = keysToLowerCase(val);
				} else {
					data[key] = val;
				}
			});
			return data;
		}

		function makeRef(ref, tail) {
			return (ref ? ref + ':' : '') + tail;
		}

		function createRelatedProducts(attr, addOns, quantity, isNew) {
			var availableProducts = CS.Service.getAvailableProducts(attr.reference);
			var defId = availableProducts[0].cscfga__Product_Definition__c;
			var currentRef = CS.Service.getCurrentConfigRef();
			var bindingCache = CS.binding;
			var promise = _.reduce(addOns, function (promise, addOn) {
				return promise.then(function () {
					return createAddOnRelatedProductInline(attr, defId, addOn, quantity, isNew);
				});
			}, emptyPromise);

			if (!availableProducts || !availableProducts.length) {
				console.error('EAPI Compatibility: no related product definitions avaialable; there should be exactly one for attribute ' + attr.reference);
				return Promise.reject('No related product available.');
			}

			return promise.then(function () {
				console.info('EAPI compatibility: evaluating rules after adding related product');
				CS.Rules.evaluateAllRules();
				return waitForRulesToComplete().then(function () {
					return lookupPromise;
				}).then(function () {
					CS.Rules.evaluateAllRules(); 
					return waitForRulesToComplete();
				}).then(function () {
					updateDisplay();
				});
			});
		}

		function createAddOnRelatedProductInline(attr, defId, addOn, quantity, isNew) {
			var parent = CS.getConfigurationWrapper(CS.Util.getParentReference(attr.reference));
			return loadProduct(defId).then(function () {
				return createConfiguration(attr.reference, defId, parent);
			}).then(function (config) {
				console.info('Created Configuration: ', config);
				var anchorRef = CS.Util.getAnchorReference(attr.reference);
				var wrapper = CS.getConfigurationWrapper(anchorRef);
				CS.binding.update(anchorRef, { 'relatedProducts': wrapper.relatedProducts });
				var bindingCache = CS.binding;
				var currentRef = CS.Service.getCurrentConfigRef();

				return new Promise(function (resolve, reject) {
					var offScreen = getOffScreenElement();
					var ref = CS.Service.getCurrentScreenRef();

					var html = CS.DataBinder.buildScreen(CS.Service.getCurrentScreenRef(), CS.Service.config, CS.screens);
					var screen = jQuery(html);
					CS.screens[CS.Service.getCurrentScreenIndex()] = screen;

					jQuery(':root').append('<div id="configurationContainerTmp"></div>');

					var prodIndex = CS.Service.getProductIndex(CS.Service.getCurrentProductId());
					var globalIndex = CS.Service.getProductIndex();
					var lcs = _.filter(globalIndex.all, function (it) {
						return it.attributes && it.attributes.type === 'cscfga__Lookup_Config__c';
					});
					_.each(lcs, function (it) {
						if (!prodIndex.all[it.Id]) {
							prodIndex.all[it.Id] = it;
						}
					});
					try {
						CS.DataBinder.bind(CS.Service.config, CS.Service.getProductIndex(), jQuery('#configurationContainerTmp').add(CS.screens[CS.Service.getCurrentScreenIndex()]), config.reference);
					} catch (error) {
						console.warn('createAddOnRelatedProductInline: got error binding model, continuing... ', error);
					}
					var context = { ref: config.reference };
					console.info('EAPI compatibility: setLookupAttributeValue ', CS.Util.generateReference(ADD_ON_ASSOC_ATTR_NAME, context), addOn.id);
					CS.setAttributeValue(CS.Util.generateReference(QUANTITY_ATTR_NAME, context), quantity);

					setLookupAttributeValue(CS.Util.generateReference(ADD_ON_ASSOC_ATTR_NAME, context), addOn.id).then(function () {
						var validation = CS.Service.validateCurrentConfig();
						if (validation.isValid) {
							CS.setConfigurationProperty(config.reference, 'status', 'Valid');
						}

						if (config.reference === wrapper.reference) {
							delete wrapper.unsaved;
						}
						delete config.unsaved;
						delete config.snapshot;
						resolve();
					});
				}).catch(function (error) {
					console.error(error);
				});
			});
		}

		function getOffScreenElement() {
			var el = jQuery('#offScreenElement');
			if (!el.size()) {
				jQuery('body').append('<div style="display: none"><div id="offScreenElement"></div></div>');
				el = jQuery('#offScreenElement');
			}
			return el;
		}

		function loadProduct(id) {
			var index = CS.Service.getProductIndex(id);
			if (!index) {
				return CS.Service.loadProduct(id, function (index) {
					jQuery.extend(CS.screens, CS.DataBinder.prepareScreenTemplates(index));
					return index;
				});
			} else {
				return emptyPromise;
			}
		}

		function getContext(ref, attrName, idx, parent) {
			return { ref: ref, attrName: attrName, index: idx || 0, parent: parent };
		}

		function buildConfig(def, reference, context) {
			var prefix = CS.Util.configuratorPrefix;
			var wrapper = {
				"reference": reference,
				"config": {
					"attributes": {
						"type": "Product_Configuration__c"
					}
				}
			};
			wrapper.config[prefix + 'Attribute_Name__c'] = context.attrName;
			wrapper.config[prefix + 'Billing_Frequency__c'] = CS.getFrequencyValueForName(def[prefix + 'Default_Billing_Frequency__c']);
			wrapper.config[prefix + 'Contract_Term__c'] = def[prefix + 'Default_Contract_Term__c'];
			wrapper.config[prefix + 'Contract_Term_Period__c'] = CS.getPeriodValueForName(def[prefix + 'Default_Contract_Term_Period__c']);
			wrapper.config[prefix + 'Description__c'] = def[prefix + 'Description__c'];
			wrapper.config[prefix + 'Index__c'] = context.index;
			wrapper.config[prefix + 'Last_Screen_Index__c'] = 0;
			wrapper.config.Name = CS.Util.getFirstDefinedValue([def.Name, def[prefix + 'Description__c']]);
			wrapper.config[prefix + 'Product_Definition__c'] = def.Id;
			wrapper.config[prefix + 'Recurrence_Frequency__c'] = CS.getFrequencyValueForName(def[prefix + 'Default_Frequency__c']);
			wrapper.config[prefix + 'Configuration_Status__c'] = 'Valid';
			wrapper.config[prefix + 'Validation_Message__c'] = '';
			wrapper.config[prefix + 'Product_Family__c'] = def.Name.length > 40 ? def.Name.substr(0, 40) : def.Name;

			return wrapper;
		}

		function buildAttribute(def, context, selectOptions, attributeFields) {
			context = context || {};
			var prefix = CS.Util.configuratorPrefix;
			var wrapper = {
				"attr": {
					"attributes": {
						"type": prefix + "Attribute__c"
					}
				},
				"attributeFields": {},
				"definitionId": def.Id,
				"displayInfo": context.displayInfo || def[prefix + 'Type__c'],
				"reference": CS.Util.generateReference(def.Name, context),
				"relatedProducts": [],
				"selectOptions": selectOptions
			};
			var typeInfo = { 'type': def[prefix + 'Data_Type__c'], 'scale': def[prefix + 'Scale__c'] };

			wrapper.attr[prefix + "Attribute_Definition__c"] = def.Id;
			wrapper.attr[prefix + 'Cascade_value__c'] = def[prefix + 'Cascade_value__c'];
			wrapper.attr[prefix + 'Display_Value__c'] = def[prefix + 'Type__c'] === 'Calculation' ? null : CS.DataConverter.localizeValue(def[prefix + 'Default_Value__c'], typeInfo);
			wrapper.attr[prefix + 'Hidden__c'] = def[prefix + 'Hidden__c'];
			wrapper.attr[prefix + 'is_active__c'] = true;
			wrapper.attr[prefix + 'Is_Line_Item__c'] = def[prefix + 'Is_Line_Item__c'];
			wrapper.attr[prefix + 'Is_Required__c'] = def[prefix + 'Required__c'];
			wrapper.attr[prefix + 'Line_Item_Sequence__c'] = def[prefix + 'Line_Item_Sequence__c'];
			wrapper.attr[prefix + 'Line_Item_Description__c'] = def[prefix + 'Line_Item_Description__c'];
			wrapper.attr.Name = def.Name;
			wrapper.attr[prefix + 'Price__c'] = def[prefix + 'Base_Price__c'] || 0;
			wrapper.attr[prefix + 'Value__c'] = def[prefix + 'Type__c'] === 'Calculation' ? '' : CS.DataConverter.normalizeValue(def[prefix + 'Default_Value__c'], typeInfo);
			wrapper.attr[prefix + 'Recurring__c'] = def[prefix + 'Recurring__c'];

			if (def[prefix + 'Type__c'] === 'Select List' && def[prefix + 'Default_Value__c'] && selectOptions) {
				for (var i = 0; i < selectOptions.length; i++) {
					if (selectOptions[i] == def[prefix + 'Default_Value__c']) {
						wrapper.attr[prefix + 'Display_Value__c'] = selectOptions[i].Name;
						break;
					}
				}
			}

			_.each(attributeFields, function (a) {
				setAttributeField(wrapper, a.Name, a[prefix + 'Default_Value__c']);
			});

			return wrapper;
		}

		function createConfiguration(anchorRef, newProductId, parent, promiseContainer) {
			var configData = CS.Service.config;
			var productIndex = CS.Service.getProductIndex(newProductId);

			CS.Log.info('EAPI Compatibility createConfiguration(): ', anchorRef, '/', newProductId, '/', parent);

			if (!productIndex) {
				throw 'Product index for ' + newProductId + ' not found';
			}

			var productDef = productIndex.productsById[newProductId],
			    wrapper = configData[anchorRef],
			    newAttrDefs = productIndex.attributeDefsByProduct[newProductId],
			    idx = 0,
			    name,
			    newConfig = {},
			    context,
			    attr,
			    defId,
			    ref;

			if (anchorRef !== ROOT_REFERENCE && !wrapper) {
				return error('Could not locate reference ', anchorRef, configData);
			}

			if (!productDef) {
				return error('Could not find product definition for id', newProductId);
			}

			if (!newAttrDefs) {
				return error('Could not find attribute definitions for product id', newProductId);
			}

			if (anchorRef === ROOT_REFERENCE) {
				ref = anchorRef;
			} else {
				idx = wrapper.relatedProducts.length;
				name = wrapper.attr.Name;
				ref = CS.Util.stripReference(anchorRef) + idx;
			}
			context = getContext(ref, name, idx, parent);

			var newConfigWrapper = buildConfig(productDef, ref, context);

			CS.Log.info('Creating configuration for reference ' + ref);

			if (anchorRef !== ROOT_REFERENCE) {
				newConfigWrapper.parent = parent;
				newConfigWrapper.unsaved = true;
				var relatedProducts = wrapper.relatedProducts.slice(0);
				relatedProducts[idx] = newConfigWrapper;
				CS.binding.update(anchorRef, { relatedProducts: relatedProducts });
			}

			var attrContext = { ref: context.ref, index: 0 };

			for (defId in newAttrDefs) {
				attr = buildAttribute(newAttrDefs[defId], attrContext, productIndex.find('selectOptionsByAttribute', defId), productIndex.find('attributeFieldDefsByAttributeDef', defId));
				configData[attr.reference] = attr;
			}
			var customLookupConfigs = getCustomLookupConfigs(newAttrDefs, productIndex);

			populateScreens(newProductId, newConfigWrapper);

			if (configData[ref]) {
				_.extend(configData[anchorRef], newConfigWrapper);
			} else {
				configData[ref] = newConfigWrapper;
			}

			var linkedObjectPropertiesCacheKey = CS.Service.getLinkedObjectId() + '|' + newProductId;

			var linkedObjectPropertiesExist = CS.Util.isObject(configData[ref]['linkedObjectProperties']);
			var linkedObjectApiExists = CS.Service.loadLinkedObjectProperties instanceof Function && CS.Service.getLinkedObjectId instanceof Function;

			if (linkedObjectPropertiesExist) {
				if (window["linkedObjectPropertiesCache"] == undefined) {
					var linkedObjectPropertiesCache = {};
				}
				if (!linkedObjectPropertiesCache.hasOwnProperty(linkedObjectPropertiesCacheKey)) {
					linkedObjectPropertiesCache[linkedObjectPropertiesCacheKey] = configData[ref]['linkedObjectProperties'];
				}
			}

			loadRulesForConfig(ref, productDef);

			if (linkedObjectPropertiesExist || !linkedObjectApiExists) {
				console.warn('EAPI compatibility: linked properties exist – loading rules for config');
				loadRulesForConfig(ref, productDef);
			} else {
				var _loadLinkedObjectProperties = function _loadLinkedObjectProperties(deferred, params) {
					var key = params.linkedObjectPropertiesCacheKey;
					if (CS.Util.isObject(params.linkedObjectPropertiesCache[key])) {
						CS.Log.info('***** Linked object properties cache hit, cache key: ', key);
						params.configData[params.ref]['linkedObjectProperties'] = params.linkedObjectPropertiesCache[key];
						deferred.resolve(params);
					} else {
						CS.Log.info('***** Loading linked object properties (deferred)...');
						params.api.loadLinkedObjectProperties(params.api.getLinkedObjectId(), params.newProductId, function linkedObjectPropertiesCallback(linkedObjectProperties) {
							if (!CS.Util.isObject(linkedObjectProperties)) {
								linkedObjectProperties = {};
							}
							params.linkedObjectPropertiesCache[params.linkedObjectPropertiesCacheKey] = params.configData[params.ref]['linkedObjectProperties'] = linkedObjectProperties;
							deferred.resolve(params);
						});
					}
				};

				var _loadCustomLookupReferencedAttributes = function _loadCustomLookupReferencedAttributes(deferred, params) {
					if (!params.configData[params.ref]['customLookupReferencedAttributes'] && Object.keys(params.customLookupConfigs).length > 0) {
						CS.Log.info('***** Loading Custom Lookup Referenced Attributes (deferred) ...');

						params.api.loadCustomLookupReferencedAttributes(JSON.stringify(params.customLookupConfigs), function (customLookupReferencedAttributes) {
							if (CS.Util.isObject(customLookupReferencedAttributes)) {
								params.configData[params.ref]['customLookupReferencedAttributes'] = customLookupReferencedAttributes;
							}
							deferred.resolve(params);
						});
					} else {
						CS.Log.info('***** NOT Loading Custom Lookup Referenced Attributes (already loaded) ...');
						deferred.resolve(params);
					}
				};

				var _loadRulesForConfig = function _loadRulesForConfig() {
					CS.Log.info('***** Loading rules for configuration (deferred)...', ref, productDef);
					loadRulesForConfig(ref, productDef);
				};

				console.warn('EAPI compatibility: linked properties do not exist – starting promise chain');

				var self = this;
				if (!promiseContainer || !promiseContainer.promise) {
					promiseContainer = {};

					var executionChain = CS.Util.getDeferred();
					promiseContainer.promise = CS.Util.getPromise(executionChain);
					executionChain.resolve();
				}
				promiseContainer.promise = promiseContainer.promise.then(CS.Util.defer(function (d) {
					d.resolve({
						api: api,
						configData: configData,
						customLookupConfigs: customLookupConfigs,
						linkedObjectPropertiesCache: linkedObjectPropertiesCache,
						linkedObjectPropertiesCacheKey: linkedObjectPropertiesCacheKey,
						newProductId: newProductId,
						ref: ref
					});
				})).then(CS.Util.defer(_loadLinkedObjectProperties, self)).then(CS.Util.defer(_loadCustomLookupReferencedAttributes, self)).then(_loadRulesForConfig);
			}

			CS.Log.info('###>>> Ending createConfiguration(): ', newConfigWrapper);
			return newConfigWrapper;
		}

		function loadRulesForConfig(reference, productDef) {
			CS.Log.info('EAPI compatibilty: loadRulesForConfig', reference, productDef);
			if (CS.Rules.hasRules(reference)) {
				return;
			}

			var referenceField = CS.Util.configuratorPrefix + 'reference__c';
			if (!productDef.hasOwnProperty(referenceField)) {
				CS.Log.error('Could not find the field reference__c in the current product definition', productDef);
				return;
			}

			var definitionRef = productDef[referenceField];
			if (!definitionRef) {
				CS.Log.error('Current product definition\'s reference is not defined: ', productDef);
				return;
			}

			var tpl = jQuery('#' + CS.Util.generateId(definitionRef) + '__rules');
			var idx = 0; 

			if (tpl.size() === 0) {
				CS.Log.warn('Could not find rules template with reference: ' + definitionRef);
			} else {
				var rules = CS.Util.applyContext(tpl.get(0).innerHTML, idx, reference);
				CS.Rules.addRules(reference, rules);
			}
		}

		function populateScreens(productId, config) {
			var productIndex = CS.Service.getProductIndex(productId),
			    screensByParent = null,
			    configScreens = [],
			    attrRefsByDef = {},
			    newAttrDefs = productIndex.attributeDefsByProduct[productId],
			    attrContext = { ref: '', index: 0 };
			var prefix = CS.Util.configuratorPrefix;

			var screenFlowName = CS.Service.getScreenFlowName();
			var usesScreenflow = false;
			if (screenFlowName !== '') {
				var flowIdsByProduct = productIndex.screenFlowIdsByNameAndProduct[screenFlowName];
				if (flowIdsByProduct && flowIdsByProduct[productId]) {
					var screenFlowId = flowIdsByProduct[productId];
					screensByParent = productIndex.screensByScreenFlow[screenFlowId];
					usesScreenflow = true;
				}
			}
			if (!usesScreenflow) {
				screensByParent = productIndex.screensByProduct[productId];
			}

			for (var defId in newAttrDefs) {
				var ref = CS.Util.generateReference(newAttrDefs[defId].Name, attrContext);
				attrRefsByDef[defId] = ref;
			}

			for (var idx in screensByParent) {
				var screen = screensByParent[idx];
				var attrs = productIndex.attributeDefsByScreen[screen.Id];
				var attrRefs = [];

				for (var attrId in attrs) {
					attrRefs.push(attrRefsByDef[attrId]);
				}

				var screenSections = productIndex.screenSectionsByScreen[screen.Id];
				var screenSectionIds = [];

				_.each(productIndex.screenSectionsByScreen[screen.Id], function (screenSection) {
					screenSectionIds.push(screenSection.Id);
				});
				_.each(Object.keys(productIndex.sectionsMapByAttributeDef), function (attributeDefId) {
					var attributeScreenSections = Object.keys(productIndex.sectionsMapByAttributeDef[attributeDefId]);
					if (_.intersection(screenSectionIds, attributeScreenSections).size() > 0) {
						attrRefs.push(attrRefsByDef[attributeDefId]);
					}
				});

				configScreens[idx] = {
					id: screen.Id,
					reference: screen._reference,
					attrs: attrRefs
				};
				if (!config.config[prefix + "Screen_Flow__c"] && screen[prefix + "Screen_Flow__c"]) {
					config.config[prefix + "Screen_Flow__c"] = screen[prefix + "Screen_Flow__c"];
				}
			}

			config.screens = configScreens;
		}

		function getCustomLookupConfigs(attributeDefinitions, productIndex) {
			var customLookupConfigs = {};
			var prefix = CS.configuratorPrefix;

			for (var defId in attributeDefinitions) {
				if (!attributeDefinitions.hasOwnProperty(defId)) {
					continue;
				}

				var lookupConfigId = attributeDefinitions[defId][prefix + "Lookup_Config__c"];
				if (lookupConfigId) {
					var lookupConfig = productIndex.all[lookupConfigId];
					var lookupCustomisationClass = lookupConfig[prefix + "lookup_customisations_impl__c"];
					if (lookupCustomisationClass && !customLookupConfigs[lookupConfigId]) {
						customLookupConfigs[lookupConfigId] = lookupConfig[prefix + "lookup_customisations_impl__c"];
					}
				}
			}

			return customLookupConfigs;
		}

		function setAttributeField(wrapper, fieldName, value) {
			var attributeFields = wrapper.attributeFields;
			var field;
			var prefix = CS.Util.configuratorPrefix;

			if (!attributeFields) {
				wrapper.attributeFields = attributeFields = {};
			}

			field = attributeFields[fieldName];

			if (!field) {
				attributeFields[fieldName] = field = {
					attributes: {
						"type": prefix + "Attribute_Field__c"
					},
					Name: fieldName
				};
			}

			field[prefix + 'Value__c'] = value;

			return field;
		}

		function setOldPriceItemValue(ref) {
			CS.EAPI.oldValue = CS.getAttributeValue(ref);
		}

		function setConfigContainerSelector(sel) {
			configContainerSelector = sel;
		}

		function bindPriceItemOnChange(ref) {
			CS.binding.getBindings(ref)[0].dataBinder.on('afterupdate', function () {
				if (CS.getAttributeValue(ref) != CS.EAPI.oldValue) {
					var prop = {};
					prop.value = CS.getAttributeValue(ref);
					prop._oldVal = CS.EAPI.oldValue;
					priceItemOnChangeHandler(ref, CS.EAPI.oldValue, prop);
					setOldPriceItemValue(ref);
				}
			});
			return Promise.resolve();
		}

		function getPriceItemRef() {
			var priceItemAttr = findPriceItemAttributeForConfigRef(CS.Service.getCurrentConfigRef());
			return priceItemAttr.reference;
		}

		function updateDisplay() {
			CS.Service.displayScreen(CS.Service.getCurrentScreenIndex(), '#configurationContainerTmp', function () {
				var newScreen = jQuery('#configurationContainerTmp').contents();
				setTimeout(function () {
					jQuery(configContainerSelector).empty().append(newScreen);
					jQuery('#configurationContainerTmp').remove();
					var html = '<div id="pmwgt" class="pmWidget dropdown pbButton CS_configButtons"><button class="dropbtn ppbButton CS_configButtons">Building Widget</button></div>';
					if (jQuery('#pmwgt')[0] == undefined) {
						var ref = CS.Service.getCurrentConfigRef();
						if (ref !== "") {
							ref = ref + '\\:';
						}
					}
					if (scope && scope.afterDisplay) {
						scope.afterDisplay();
					}
					CS.EAPI.findAddOnRelatedProductAttributes(CS.Service.getCurrentConfigRef()).then(function (attrs) {
						_.each(attrs, function (attr) {
							jQuery('[data-cs-control="' + attr.reference + '"][data-cs-action="addRelatedProduct"]').css({ display: 'none' });
						});
						if (typeof window.renderLookups === 'function') {
							renderLookups();
						}
					});
				}, 300);
			});
		}

		function waitForRulesToComplete(state) {
			function continueWaiting(state) {
				return new Promise(function (resolve, reject) {
					window.setTimeout(function (state) {
						return waitForRulesToComplete(state).then(resolve);
					}, 250, state);
				});
			}

			if (!state) {
				state = { c: 1, sc: 1 };
			}

			if (state.c > 40 || CS.rulesTimer === undefined && !CS.lookupQueriesAreQueued()) {
				if (state.sc < 2) {
					state.sc += 1;
					state.c = 1;
					console.log('waitForRulesToComplete: waiting for secondary evaluation...');
					return continueWaiting(state);
				}
				console.log('waitForRulesToComplete: rules complete.');
				return Promise.resolve();
			} else {
				state.c += 1;
				state.sc = 1;
				console.log('waitForRulesToComplete: waiting... ' + state.c);
				return continueWaiting(state);
			}
		}

		function resetWidget() {
			emptyPromise = Promise.resolve();
			rulesFunction = undefined;
			lookupPromise = Promise.resolve();
			numberOfAddOns = 0;
			configAttrCache = {};
			priceItemAttrCache = {};
			onChangeHandlers = {};
			handlersBound = false;
			if (lookupDeletePollerInterval) {
				window.clearInterval(lookupDeletePollerInterval);
				lookupDeletePollerInterval = undefined;
			}
			rateCards = {};
			rateCardLines = {};
			selectedRateCard;
			rateCardJSON = {};
			editMode = false;
			configContainerSelector = '#configurationContainer';
			processingModel = false;
			scope = undefined;
			continiueProcessing = false;
		}

		return {
			addDefaultAddOns: addDefaultAddOns,
			insertAddOn: insertAddOn,
			createRelatedProducts: createRelatedProducts,
			displayPricingWidget: displayPricingWidget,
			createConfiguration: createConfiguration,
			createAddOnRelatedProductInline: createAddOnRelatedProductInline,
			findAddOnRelatedProductAttributes: findAddOnRelatedProductAttributes,
			overrideRelatedProductControls: overrideRelatedProductControls,
			setConfigContainerSelector: setConfigContainerSelector,
			priceItemOnChangeHandler: priceItemOnChangeHandler,
			resolveLookupValue: resolveLookupValue,
			runCompatibilityFunctionsModel2: runCompatibilityFunctionsModel2,
			setLookupAttributeValue: setLookupAttributeValue,
			setConfigurationNames: setConfigurationNames,
			setLineItemDescriptions: setLineItemDescriptions,
			setPrices: setPrices,
			waitForRulesToComplete: waitForRulesToComplete,
			findLastInputElementValue: findLastInputElementValue,
			bindPriceItemOnChange: bindPriceItemOnChange,
			getPriceItemRef: getPriceItemRef,
			displayFeatureWidget: displayFeatureWidget,
			displayRateCardWidget: displayRateCardWidget,
			getRateCardJSON: getRateCardJSON,
			cloneRateCard: cloneRateCard,
			cloneAndSelectRateCard: cloneAndSelectRateCard,
			saveRateCard: saveRateCard,
			editRateCard: editRateCard,
			resetWidget: resetWidget
		};
	} 

	CS.EAPI = CS.EAPI || {};
	_.extend(CS.EAPI, buildCompatibilityFunctions());

	var html = '' + '<div id="mySidenav" class="sidenav">' + '  <a href="javascript:void(0)" class="closebtn" onclick="closeNav()">&times;</a>' + '  <div id="tabsContainer1">' + '    <button class="btn btn-primary" onClick="showOnlyThisContainer(jQuery(\'#featureTableContainer\'))">Features</button>' + '    <button class="btn btn-primary" onClick="showOnlyThisContainer(jQuery(\'#addOnTableContainer\'))">AddOns</button>' + '    <button class="btn btn-primary"onClick="showOnlyThisContainer(jQuery(\'#rateCardTableContainer\'))">RateCard</button>' + '    <div>' + '      <div id="featureTableContainer" class="tableContainer">' + '        <div id="ftWgt" class="ftWidget dropdown pbButton CS_configButtons"><button class="dropbtn ppbButton CS_configButtons">Building Widget</button></div>' + '      </div>' + '      <div id="addOnTableContainer" class="tableContainer" style="display: none;">' + '        <div class="pmWidget dropdown pbButton CS_configButtons"><button class="dropbtn ppbButton CS_configButtons">Building Widget</button></div>' + '      </div>' + '      <div id="rateCardTableContainer" class="tableContainer" style="display: none;">' + '        <div id="rtWgt" class="rtWidget dropdown pbButton CS_configButtons"><button class="dropbtn ppbButton CS_configButtons">Building Widget</button></div>' + '      </div>' + '    </div>' + '  </div>' + '</div>' + '<span class="navButton" onclick="openNav()">&#9776;</span>';
	jQuery('#screensList').after(html);
});