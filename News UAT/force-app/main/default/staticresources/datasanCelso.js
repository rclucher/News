jQuery.noConflict();
jQuery(document).ready(function () {
    console.log('@ ready');
    if (typeof (datasan__settings) != "undefined") {
        console.log('@ ready datasan__settings:' + datasan__settings);
        jQuery(document).amaAddressControl(datasan__settings)

    }
});
(function (g) {
    var f = {};
    var l = {
        key: "",
        apiUrl: "https://rapidmatch.datasan.com.au/v1/",
        themeUrl: "https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.21/themes/",
        theme: "start",
        datasanCSS: "https://d1c24wnrse4bd3.cloudfront.net/api/sf/1.8/datasan-sf.css",
        showCopyAddress: true,
        dataType: "json",
        caps: "false",
        abbr: "false",
        defaultCountry: "Australia"
    };
    g.fn.amaAddressControl = function (w) {
        console.log('@ amaAddressControl w:' + w);
        f = g.extend({}, l, w);
        k(f.theme);
        k(f.datasanCSS);
        if (g.trim(f.key) == "") {
            d("DataSan key does not exist, please contact your administrator.");
            return this
        }
        g(f.accounts).each(function () {
            if (g.trim(this.abn) == "") {
                this.abn = this.account + "_abn"
            }
            i(this)
        });
        g(f.addresses).each(function (y, x) {

            console.log('@ g(f.addresses).each y:' + y);
            console.log('@ g(f.addresses).each x:' + x);
            console.log('@ g(f.addresses).each x.country:' + x.country);
            console.log('@ g(f.addresses).each x.state:' + x.state);
            console.log('@ g(f.addresses).each x.city:' + x.city);
            console.log('@ g(f.addresses).each x.postalcode:' + x.postalcode);
            console.log('@ g(f.addresses).each x.street:' + x.street);


            if (g.trim(x.country) == "" || g.trim(x.state) == "" || g.trim(x.city) == "" || g.trim(x.postalcode) == "" || g.trim(x.street) == "") {
                console.log('@ g(f.addresses).each returned 1');
                return
            }
            var z = x.country;
            if (x.country.search(/^(con19country|con18country|acc17country|acc18country|lea16country)$/i) == 0) {
                z = x.country.substring(0, 5);
                x.ilecell = z + "_ilecell";
                x.dpidilecell = x.dpid + "_ilecell"
            }
            if (g.trim(x.locality) == "") {
                x.locality = z + "locality"
            }
            if (g.trim(x.dpid) == "") {
                x.dpid = z + "dpid"
            }
            if (g.trim(x.localityLabel) == "") {
                x.localityLabel = "Suburb or Postcode"
            }
            if (g.trim(x.dpidLabel) == "") {
                x.dpidLabel = "DPID"
            }
            if (g.trim(x.ilecell) != "") {
                g.fn.amaAddressControl.inlineAddressControl(x)
            }


            console.log('@ g(f.addresses).each m.get(x.country):' + m.get(x.country));
            console.log('@ g(f.addresses).each g("#" + s(x.country)).size():' + g("#" + s(x.country)).size());
            console.log('@ g(f.addresses).each g("#" + s(x.state)).size():' + g("#" + s(x.state)).size());
            console.log('@ g(f.addresses).each g("#" + s(x.city)).size():' + g("#" + s(x.city)).size());
            console.log('@ g(f.addresses).each g("#" + s(x.postalcode)).size():' + g("#" + s(x.postalcode)).size()); 
            console.log('@ g(f.addresses).each g("#" + s(x.street)).size():' + g("#" + s(x.street)).size());           
            if (m.get(x.country) != null || g("#" + s(x.country)).size() == 0 || g("#" + s(x.state)).size() == 0 || g("#" + s(x.city)).size() == 0 || g("#" + s(x.postalcode)).size() == 0 || g("#" + s(x.street)).size() == 0) {
                console.log('@ g(f.addresses).each returned 2');
                return
            }

            console.log('@ g(f.addresses).each f.showCopyAddress:' + f.showCopyAddress);
            console.log('@ g(f.addresses).each m.data.length:' + m.data.length);

            m.add(new j(x));
            if (f.showCopyAddress && m.data.length == 2) {
                g(".pbSubExtra a:contains('Copy')").hide();
                m.data[0].setCopyAddress(1, 0);
                m.data[1].setCopyAddress(0, 1)
            }
        });
        return this
    };
    g.fn.amaAddressControl.inlineAddressControl = function (w) {
        console.log('@ g.fn.amaAddressControl.inlineAddressControl w:' + w);
        w.ilecell = s(w.ilecell);
        w.dpidilecell = s(w.dpidilecell);
        w.dpid = s(w.dpid);

        function x(z, y) {
            if (g("#" + z).size() > 0 && g("#" + y).size() > 0 && (/AU$/.test(g.trim(g("#" + z).text()).toUpperCase()) || /AUSTRALIA$/.test(g.trim(g("#" + z).text()).toUpperCase()))) {
                if (/\d/.test(g.trim(g("#" + y).text()))) {
                    g("#" + z).removeClass("tooltipError").addClass("tooltipOk")
                } else {
                    g("#" + z).removeClass("tooltipOk").addClass("tooltipError")
                }
            } else {
                g("#" + z).removeClass("tooltipOk").removeClass("tooltipError")
            }
        }
        x(w.ilecell, w.dpidilecell);
        g("#" + w.ilecell).removeAttr("ondblclick").dblclick(function (y) {
            if (window.sfdcPage && window.sfdcPage.hasRun) {
                sfdcPage.dblClickField(y, this);
                if (typeof (sfdcPage.oldsave) == "undefined") {
                    sfdcPage.oldsave = sfdcPage.save;
                    sfdcPage.save = function (z) {
                        this.oldsave(z);
                        window.setTimeout("window.location.reload(true);", 500)
                    }
                }
            }
            window.setTimeout(function () {
                if (m.get(w.country) == null) {
                    m.add(new j(g.extend({}, w, {
                        dpid: w.dpid + "_inline"
                    })))
                } else {
                    m.get(w.country).setValues()
                }
                g("#InlineEditDialog :button[value='OK']").click(function (z) {
                    if (g("#" + w.dpidilecell).size() > 0) {
                        sfdcPage.getInlineEditData(w.dpid).openField(sfdcPage.getFieldById(w.dpid));
                        g("#" + w.dpid).val(g("#" + w.dpid + "_inline").val());
                        sfdcPage.getInlineEditData(w.dpid).closeCurrentField()
                    }
                    g("#" + w.dpidilecell + " .inlineEditUndoLink").hide();
                    x(w.ilecell, w.dpidilecell);
                    g("#" + w.ilecell + " .inlineEditUndoLink").click(function () {
                        sfdcPage.getInlineEditData(w.dpid).resetFieldById(w.dpid);
                        x(w.ilecell, w.dpidilecell)
                    })
                });
                g("#InlineEditDialog :button[value='Cancel']").click(function (z) {
                    sfdcPage.getInlineEditData(w.dpid).resetFieldById(w.dpid)
                })
            }, 50)
        });
        g("#" + w.dpidilecell).removeAttr("ondblclick")
    };
    var i = function (w) {
        if (g("#" + s(w.abn)).size() == 0) {
            g("#" + s(w.account)).after('<input id="' + w.abn + '" name="' + w.abn + '" type="hidden">')
        }
        if (g("#" + s(w.account) + "_lookup").size() == 0) {
            var x = g("<a id='" + w.account + "_lookup' href='javascript:void(0)' title='Lookup businesses when they registered for an Australian Business Number (ABN)'>ABN Lookup</a>");
            x.click(function () {
                o(w)
            });
            g("#" + s(w.account)).parent().append("&nbsp;").append(x)
        }
    };
    var m = new function () {
            this.data = [];
            this.add = function (w) {
                if (this.get(w.id) == null) {
                    this.data.push(w)
                }
            };
            this.get = function (x) {
                for (var w = 0; w < this.data.length; w++) {
                    if (this.data[w].id == x) {
                        return this.data[w]
                    }
                }
                return null
            }
        };
    var j = function (G) {
        this.$table = g("#" + s(G.country)).parents("table").first();
        this.$country = g("#" + s(G.country));
        this.$state = g("#" + s(G.state));
        this.$city = g("#" + s(G.city));
        this.$zip = g("#" + s(G.postalcode));
        this.$street = g("#" + s(G.street));
        this.$locality = g("#" + s(G.locality));
        this.$dpid = g("#" + s(G.dpid));
        this.fields1 = [this.$street, this.$city, this.$state, this.$zip, this.$country];
        this.fields2 = [this.$country, this.$city, this.$street, this.$state, this.$zip];
        this.id = G.country;
        var I = this;
        var E = [];
        var A = [];
        var z = {};
        g.each(I.fields1, function (J, L) {
            E.push(L.parents("td").first());
            A.push(L.attr("tabindex"));
            var K = L.parents("td").first().prev();
            if (g("label", K).size() == 0) {
                K.html("<label>" + K.html() + "</label>")
            }
            z[L.attr("id")] = g("label", K)
        });
        this.init = function () {
            H();
            x();
            I.setValues();
            p(I);
            D()
        };
        this.setCopyAddress = function (L, K) {
            var J = g("<a href='javascript:void(0);'>Copy address from the other</a><br/>").click(function () {
                b(L, K);
                D()
            });
            E[0].prepend(J).prev().prepend("<br/>")
        };
        this.setValues = function () {
            if (g.trim(I.$street.val()) == "" && g.trim(I.$city.val()) == "" && g.trim(I.$state.val()) == "" && g.trim(I.$zip.val()) == "" && g.trim(I.$country.val()) == "") {
                I.$country.val(f.defaultCountry)
            }
            I.$locality.trigger("setvalue");
            if (/\d/.test(g.trim(g("#" + s(G.dpidilecell)).text()))) {
                I.$dpid.val(g.trim(g("#" + s(G.dpidilecell)).text()))
            }
        };

        function H() {
            if (I.$locality.size() == 0) {
                I.$city.parent().prev().prepend('<label for="' + G.locality + '">' + G.localityLabel + "</label>");
                I.$city.parent().prepend('<input id="' + G.locality + '" name="' + G.locality + '" size="' + 30 + '" maxlength="' + 80 + '" tabindex="' + I.$country.attr("tabindex") + '" type="text">');
                I.$locality = g("#" + s(G.locality));
                z[I.$locality.attr("id")] = g("label", I.$locality.parent().prev())
            }
            if (g.trim(G.dpid).indexOf("_inline") > 0 && I.$dpid.size() == 0) {
                I.$country.parents("tr").first().after('<tr><td class="labelCol"><label for="' + G.dpid + '">' + G.dpidLabel + '</label></td><td class="dataCol"><input id="' + G.dpid + '" name="' + G.dpid + '" size="' + 10 + '" maxlength="' + 10 + '" tabindex="' + I.$country.attr("tabindex") + '" type="text"></td></tr>');
                I.$dpid = g("#" + s(G.dpid))
            }
            I.fields = [I.$country, I.$city, I.$street, I.$state, I.$zip, I.$locality, I.$dpid]
        }

        function x() {
            I.$country.bind("autocompletechange", function () {
                D();
                I.$dpid.trigger("clear")
            });
            I.$locality.bind("autocompletechange", function () {
                I.$street.trigger("clear");
                I.$locality.trigger("split")
            }).bind("keyup", function () {
                if (g.trim(I.$locality.val()) == "") {
                    I.$locality.trigger("clear")
                }
                I.$locality.trigger("split")
            }).bind("split", function () {
                var J = t(I.$locality.val());
                I.$city.val(J.city);
                I.$state.val(J.state);
                I.$zip.val(J.zip)
            }).bind("setvalue", function () {
                I.$locality.val(e(I.$city.val(), I.$state.val(), I.$zip.val()))
            }).bind("clear", function () {
                I.$locality.val("");
                I.$street.trigger("clear")
            });
            I.$city.bind("autocompletechange", function () {
                I.$street.trigger("clear")
            });
            I.$zip.bind("autocompletechange", function () {
                I.$street.trigger("clear")
            });
            I.$street.bind("keyup", function () {
                if (g.trim(I.$street.val()) == "") {
                    I.$street.trigger("clear")
                }
            }).bind("change", function () {
                I.$dpid.trigger("clear")
            }).bind("clear", function () {
                I.$street.val("");
                I.$dpid.trigger("clear")
            });
            I.$dpid.bind("clear", function () {
                I.$dpid.val("")
            })
        }

        function D() {
            if (I.$country.val().toUpperCase() == "AUSTRALIA" || I.$country.val().toUpperCase() == "AU") {
                B()
            } else {
                y()
            }
        }

        function B() {
            g.each(I.fields2, function (J, K) {
                E[J].append(K);
                E[J].prev().append(w(K))
            });
            F(I.$country);
            F(I.$locality);
            F(I.$street);
            C(I.$city);
            C(I.$state);
            C(I.$zip);
            I.$street.attr("tabindex", I.$country.attr("tabindex"));
            I.$dpid.attr("readonly", "readonly");
            n(I);
            a(I);
            q(I);
            u(I)
        }

        function y() {
            g.each(I.fields1, function (J, K) {
                E[J].append(K);
                E[J].prev().append(w(K))
            });
            F(I.$country);
            C(I.$locality);
            F(I.$street);
            F(I.$city);
            F(I.$state);
            F(I.$zip);
            I.$street.attr("tabindex", A[0]);
            I.$dpid.removeAttr("readonly");
            I.$locality.autocomplete("destroy");
            I.$city.autocomplete("destroy");
            I.$zip.autocomplete("destroy");
            I.$street.autocomplete("destroy")
        }

        function F(J) {
            J.show();
            w(J).show();
            J.parents("tr").first().show()
        }

        function C(J) {
            J.hide();
            w(J).hide();
            if (g("input:visible", J.parents("tr").first()).size() == 0) {
                J.parents("tr").first().hide()
            }
        }

        function w(J) {
            return z[J.attr("id")]
        }
        this.init()
    };

    function k(w) {
        var x = document.createElement("link");
        x.rel = "stylesheet";
        x.type = "text/css";
        x.href = w;
        if (w.indexOf("/") == -1) {
            x.href = f.themeUrl + w + "/jquery-ui.css"
        }
        document.getElementsByTagName("head")[0].appendChild(x)
    }

    function p(w) {
        var y = function (z) {
            if (z.label.toUpperCase().indexOf(w.$country.val().toUpperCase()) == 0) {
                return {
                    label: g.trim(z.label).toUpperCase()
                }
            }
        };
        var x = function (z, A) {
            w.$country.val(A.item.label);
            z.stopPropagation();
            return false
        };
        g(w.$country).autocomplete({
            source: function (A, z) {
                A.term = "country";
                var B = f.apiUrl + "countries?auth_token=" + h(f.key);
                r(A, z, B, y)
            },
            focus: function (z, A) {
                return false
            },
            select: x
        })
    }

    function n(w) {
        v(w, w.$city)
    }

    function a(w) {
        v(w, w.$zip)
    }

    function q(w) {
        v(w, w.$locality)
    }

    function v(w, z) {
        var y = function (B) {
            var A = e(g.trim(B.locality_name), g.trim(B.state), g.trim(B.postcode));
            return {
                label: c(A),
                city: c(g.trim(B.locality_name)),
                zip: g.trim(B.postcode),
                state: c(g.trim(B.state)),
                id: g.trim(B.locality_id)
            }
        };
        var x = function (A, B) {
            w.$city.val(B.item.city);
            w.$zip.val(B.item.zip);
            w.$state.val(B.item.state);
            w.$locality.val(B.item.label);
            A.stopPropagation();
            return false
        };
        g(z).autocomplete({
            source: function (C, A) {
                var B = f.apiUrl + "address_line_2?auth_token=" + h(f.key) + "&locality_or_postcode=" + h(z.val()) + "&abbr=" + h(f.abbr);
                r(C, A, B, y)
            },
            focus: function (A, B) {
                return false
            },
            select: x
        })
    }

    function u(w) {
        var y = function (z) {
            return {
                label: c(z.address_line_1),
                dpid: z.delivery_point_id,
                city: c(z.locality_name),
                zip: z.postcode,
                state: c(z.state)
            }
        };
        var x = function (z, A) {
            w.$city.val(A.item.city);
            w.$zip.val(A.item.zip);
            w.$state.val(A.item.state);
            w.$locality.trigger("setvalue");
            w.$street.val(A.item.label);
            w.$dpid.val(A.item.dpid);
            z.stopPropagation();
            return false
        };
        g(w.$street).autocomplete({
            search: function (z, A) {
                if (g.trim(w.$city.val()) == "" && g.trim(w.$zip.val()) == "") {
                    return false
                }
                return true
            },
            source: function (B, z) {
                var A = f.apiUrl + "address_line_1?auth_token=" + h(f.key) + "&locality_and_postcode=" + h(w.$city.val() + " " + w.$zip.val()) + "&address_line_1=" + h(w.$street.val()) + "&abbr=" + h(f.abbr);
                r(B, z, A, y)
            },
            focus: function (z, A) {
                return false
            },
            select: x
        })
    }

    function o(z) {
        var y = g.trim(g("#" + s(z.account)).val());
        if (y == "") {
            return
        }
        var x = g("<div id='dialog-confirm' title='ABN Lookup services'></div>").append("<table style='border-collapse:collapse;padding:4px;width:100%;' class='lktable ui-widget ui-widget-content'><tr><td width='20%'><label for='lkname'><b>Company Name</b></label></td><td><input id='lkname' maxlength='80' name='lkname' size='50' type='text' value='" + y + "'></td><td><input value=' Search ' class='btn' id='lksearch' type='button'></td></tr></table>").append("<div id='dialog-content' style='margin-top:1em;'></div>");
        g(x).dialog({
            width: 600,
            height: 400,
            modal: true,
            draggable: true,
            resizable: false,
            close: function (A, B) {
                g(x).dialog("destroy");
                g(x).remove()
            }
        });
        g("#lksearch").click(function () {
            w(g("#lkname").val())
        });
        g("#lkname").keypress(function (A) {
            if (A.keyCode == 13) {
                w(g("#lkname").val())
            }
        });
        w(y);

        function w(A) {
            g("#dialog-content").html("<p style='color:#ff0000;'>Loading...</p>");
            g("#lkname").addClass("ui-autocomplete-loading");
            jQuery.ajax({
                url: f.apiUrl + "company_lookup?auth_token=" + h(f.key) + "&name=" + h(A),
                dataType: f.dataType,
                type: "get",
                error: function (B) {
                    g(".ui-autocomplete-loading").removeClass("ui-autocomplete-loading");
                    g("#dialog-content").html("<p><span class='ui-icon ui-icon-alert' style='float:left; margin-right: .3em;'></span>Unexpected loading error</p>")
                },
                success: function (D) {
                    g("#lkname").removeClass("ui-autocomplete-loading");
                    var C = "";
                    var B = D.ABRPayloadSearchResults.response.exception;
                    if (typeof (B) != "undefined") {
                        C = "<h2>" + B.exceptionDescription + "</h2>"
                    } else {
                        C = "<table style='border-collapse:collapse;padding:4px;' class='lktable ui-widget ui-widget-content'>";
                        C += "<tr class='ui-widget-header'><th>Name</th><th>ABN</th><th>State</th><th>Postcode</th><th>Status</th></tr>";
                        g.each(g(D.ABRPayloadSearchResults.response.searchResultsList.searchResultsRecord), function (K, M) {
                            var E = "";
                            var J = M.mainName || M.mainTradingName || M.otherTradingName;
                            if (J != null) {
                                E = J.organisationName
                            }
                            if (E == "" && M.legalName != null) {
                                E = M.legalName.fullName
                            }
                            var G = M.ABN.identifierValue;
                            var H = M.ABN.identifierStatus;
                            var L = M.mainBusinessPhysicalAddress.stateCode;
                            var I = M.mainBusinessPhysicalAddress.postcode;
                            var F = "background:#fff;";
                            if (K % 2 == 0) {
                                F = "background:#f2f2f2;"
                            }
                            C += "<tr style='" + F + "'><td width='50%'><b><a href='javascript:void(0)'>" + E + "</a></b></td><td>" + G + "</td><td>" + L + "</td><td>" + I + "</td><td>" + H + "</td></tr>"
                        });
                        C += "</table>";
                        C += "<p><span class='ui-icon ui-icon-info' style='float:left; margin-right: .3em;'></span>" + D.ABRPayloadSearchResults.response.usageStatement + "</p>"
                    }
                    g("#dialog-content").html(C);
                    g(".lktable").css("width", g("#dialog-content").innerWidth() + "px");
                    g("a", g("#dialog-content")).click(function () {
                        g("#" + s(z.account)).val(g(this).parent().text());
                        g("#" + s(z.abn)).val(g(this).parents("td").first().next().text());
                        g(x).dialog("destroy");
                        g(x).remove()
                    })
                }
            })
        }
    }

    function t(x) {
        var y = x.match(/\d{4}/) ? x.match(/\d{4}/)[0] : "";
        var w = x.match(/\bNSW\b|\bACT\b|\bVIC\b|\bQLD\b|\bSA\b|\bWA\b|\bTAS\b|\bNT\b/i);
        var z = w ? w[0] : "";
        var A = g.trim(x.replace(y, "").replace(/\bNSW\b|\bACT\b|\bVIC\b|\bQLD\b|\bSA\b|\bWA\b|\bTAS\b|\bNT\b/i, "").replace(/,/g, ""));
        return {
            city: A,
            state: z,
            zip: y
        }
    }

    function e(z, y, x) {
        var w = g.trim(z);
        if (w != "") {
            w += ", " + g.trim(y)
        }
        if (w != ", ") {
            w += " " + g.trim(x)
        }
        return g.trim(w)
    }

    function r(z, w, x, y) {
        jQuery.ajax({
            url: x,
            dataType: f.dataType,
            type: "get",
            success: function (B) {
                var A = jQuery(B.response.docs).map(function (C) {
                    return y(this)
                });
                w(A);
                g(".ui-autocomplete-loading").removeClass("ui-autocomplete-loading")
            },
            error: function (A) {
                g(".ui-autocomplete-loading").removeClass("ui-autocomplete-loading")
            }
        })
    }

    function h(w) {
        return encodeURIComponent(g.trim(w))
    }

    function c(w) {
        if (f.caps == "true") {
            return g.trim(w).toUpperCase()
        } else {
            return w
        }
    }

    function s(w) {
        if (w == null || w == "undefined") {
            return null
        }
        return w.replace(/(:|\.)/g, "\\$1")
    }

    function b(x, w) {
        if (m.data.length > 1) {
            g.each(m.data[w].fields, function (y, z) {
                z.val(m.data[x].fields[y].val());
                if (m.data[x].fields[y].attr("readonly")) {
                    z.attr("readonly", "readonly")
                } else {
                    z.removeAttr("readonly")
                }
            })
        }
    }

    function d(w) {
        if (typeof (w) == "undefined") {
            return
        }
        g("#ama_message").html('<div class="ui-state-error ui-corner-all" style="padding: 0 .7em;"><p><span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span><span>' + w + "<span></p></div>")
    }
    g.extend(g.ui.autocomplete.prototype, {
        _renderItem: function (w, x) {
            return g("<li></li>").data("item.autocomplete", x).append(g("<a></a>").html(x.label)).appendTo(w)
        },
        _renderMenu: function (y, x) {
            var w = this;
            g.each(x, function (z, A) {
                w._renderItem(y, A)
            });
            w.menu.element.appendTo(w.element.parent())
        }
    });
    if (window.XDomainRequest && !g.support.cors) {
        g.ajaxTransport(function (x) {
            var w;
            return {
                send: function (z, y) {
                    w = new XDomainRequest();
                    w.open(x.type, x.url);
                    w.onload = function () {
                        y(200, "OK", {
                            text: w.responseText
                        }, "Content-Type: " + w.contentType)
                    };
                    if (x.xhrFields) {
                        w.onerror = x.xhrFields.error;
                        w.ontimeout = x.xhrFields.timeout
                    }
                    w.send((x.hasContent && x.data) || null)
                },
                abort: function () {
                    if (w) {
                        w.abort()
                    }
                }
            }
        })
    }
})(jQuery);