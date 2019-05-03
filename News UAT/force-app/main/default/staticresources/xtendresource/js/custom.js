jQuery(function() {

    "use strict";

    var toggles = jQuery( "#hamburger" );
    var toggle = toggles[0];
    var mnav = jQuery( "#mobile-nav" );
    var mn = mnav[0];

    function toggleHandler(toggle) {
        toggle.addEventListener( "click", function(e) {
            e.preventDefault();
            (this.classList.contains("is-active") === true) ? this.classList.remove("is-active") : this.classList.add("is-active");
            (mn.classList.contains("open") === true) ? mn.classList.remove("open") : mn.classList.add("open");
        });
    }
    if(!jQuery.isEmptyObject(toggle))
    { toggleHandler(toggle);}
    onWindowResize();
    positionMapMarkers();
    openInvestorAccordion();

    // content for responsive tables
    if(window.innerWidth < 992){
        renderMobileTables();
        jQuery(".dataTables_paginate a").not(".ui-state-disabled").click(function(){
            renderMobileTables();
        });
        jQuery(".dataTables_length select").change(function(){
            renderMobileTables();
        });
        jQuery(".dataTables_filter input").change(function(){
            renderMobileTables();
        });
	}

    // add class for table select
    //jQuery(".dataTables_length select").addClass("selectpicker");
	//jQuery(".dataTables_length select").selectpicker();
    jQuery(".dataTables_length select").css("display", "block!important");

    diffSizeTabOffset();
	
	jQuery("#mobile-nav").after('<div id="offset-top">');
	
});


/*
 *  Window Resize
 *
 *  Fires off stuff when the window is resized. Waits for 500 ms,
 *  so it is not continuously called.
 */

function onWindowResize() {
    var timeoutID;

    jQuery( window ).resize( function() {
        clearTimeout( timeoutID );
        timeoutID = setTimeout( doneResizing, 500 );

        // content for responsive tables
        if(window.innerWidth < 992){
            renderMobileTables();
            jQuery(".dataTables_paginate a").not(".ui-state-disabled").click(function(){
                renderMobileTables();
            });
            jQuery(".dataTables_length select").change(function(){
                renderMobileTables();
            });
            jQuery(".dataTables_filter input").change(function(){
                renderMobileTables();
            });
        }
    });

    diffSizeTabOffset();

    function doneResizing() {
        positionMapMarkers();
    }
};

// add tab hash for url
function tabHash(headerHeight){
    var hash = window.location.hash;
    hash && jQuery(".nav-tabs a[href='" + hash + "']").tab("show");

    jQuery(window).load(function(e){
        if(window.location.hash){
            jQuery(this).scrollTop(0);
        }
    });
    jQuery(".nav-tabs a").click(function(e){
        jQuery(this).tab("show");
        history.pushState(null, null, this.hash);
    });
  jQuery("a").click(function(e){
        if(jQuery(this).prop("hash")){
			var hrefLink = jQuery(this).prop("href");
			var matchLink = hrefLink.match(/(.*)#/);
			var matchLink2 = String(matchLink).match(/[^/]*$/)[0];
			
			var currentUrl = window.location.href;
			var matchUrl = currentUrl.match(/(.*)#/);
			var matchUrl2 = String(matchUrl).match(/[^/]*$/)[0];
			
			if(matchLink2 == matchUrl2){
				e.preventDefault();
				var linkHash = jQuery(this).prop("hash");
				jQuery("body").find("a[href=" + linkHash + "]").tab("show");
				history.pushState(null, null, this.hash);
			}
        }
    });
}
function diffSizeTabOffset(){
    if(window.innerWidth > 1243){
        tabHash(106);
    }
    if(window.innerWidth <= 1243){
        tabHash(180);
    }
    if(window.innerWidth <= 1112){
        tabHash(210);
    }
    if(window.innerWidth <= 992){
        tabHash(0);
    }
}

/*
 *  Position Map Markers
 */

function positionMapMarkers() {
    var containerWidth  = jQuery( '#location-map' ).outerWidth();
    var mapWidth    = jQuery( 'img', '#location-map' ).width();
    var markerOffset  = ( containerWidth - mapWidth ) / 2;

    jQuery( 'div', '#location-map' ).each( function() {
        var xOffset   = Number( jQuery( this ).attr( 'data-posx'));
        var yOffset   = Number( jQuery( this ).attr( 'data-posy'));

        jQuery( this ).css( { 'top' : yOffset, 'left' : xOffset + markerOffset });
    });

    jQuery( 'div', '#location-map' ).animate( { 'opacity' : 1 });
};

/*
 *  Mobile Nav Accordion
 */

jQuery( '.reveal' ).click( function() {

    var dropdownArrow = jQuery( this );

    if ( dropdownArrow.hasClass( 'open' ) ) {
        // add 'open' class to clicked arrow
        dropdownArrow.removeClass( 'open' );

        // close
        dropdownArrow.closest( 'li' ).find( 'ul' ).slideUp(400);
    } else {
        dropdownArrow.closest( '.nav' ).find( '.open' ).removeClass( 'open' );

        // close open subnavs
        dropdownArrow.closest( '.nav' )
            .find( 'ul' )
            .slideUp();

        // add 'open' class to clicked arrow
        dropdownArrow.addClass( 'open' );

        // open
        dropdownArrow.closest( 'li' ).find( 'ul' ).slideDown(400);
    }
});

/*
 * Investor Accordion
 */

function openInvestorAccordion() {
    var pageURI = window.location.pathname.toLowerCase();

    jQuery( '.panel-collapse' ).each( function() {
        var linkLocation = jQuery( this ).attr( 'data-location' );
        if ( pageURI.indexOf( linkLocation ) != -1 ) {
            jQuery( this ).collapse('toggle');
        }
    })
};

/*
 * Dropdown animations
 */

jQuery('.dropdown').on('show.bs.dropdown', function(e){
    jQuery('.dropdown-menu' , 'nav').stop(true,true);
    jQuery(this).find('.dropdown-menu').first().stop(true, true).fadeIn(300);
});

// ADD SLIDEUP ANIMATION TO DROPDOWN //
jQuery('.dropdown').on('hide.bs.dropdown', function(e){
    jQuery('nav .dropdown-menu').stop(true,true);
    jQuery(this).find('.dropdown-menu').first().stop(true, true).fadeOut(100);
});
/*
 * Dropdown onclick hide
 */
jQuery('.dropdown.auto-hide .dropdown-menu li').click(function(e){
	var dd = jQuery(this).parent().parent();
	
	dd.addClass('no-hover');
	setTimeout(function() {
			dd.removeClass('no-hover');
		}, 100);
});

/*
 * Remove focus from buttons after click
 */
jQuery('.btn').mouseup(function() {
    jQuery(this).blur();
});

/*
 * Remove focus from select after selection is made
 */
jQuery('select').change(function() {
    jQuery(this).blur();
});

jQuery("#csHomeCarousel").swiperight(function() {
    jQuery(this).carousel('prev');
});
jQuery("#csHomeCarousel").swipeleft(function() {
    jQuery(this).carousel('next');
});

/*jQuery("ul.nav.navbar-nav li.dropdown").hover(
    function(){
        jQuery(this).find("ul.dropdown-menu").slideDown("fast");
    },
    function(){
        jQuery(this).find("ul.dropdown-menu").slideUp("fast");
    }
);*/

function renderMobileTables(){
    jQuery("table.table").each(function(indxTable, elTable){
        jQuery(elTable).find("tbody tr").each(function(indxTr, elTr){
            for(var th = 0; th <= jQuery(elTable).find("thead tr th div div").length; th++){
                for(var td = 0; td <= jQuery(elTable).find("tbody").find(elTr).find("td").length; td++){
                    //jQuery(this).find("td").eq(th).text(jQuery(elTable).find("thead tr th span").eq(th).text());
                    jQuery(this).find("td").eq(th).attr('data-content', jQuery(elTable).find("thead tr th div div").eq(th).text());
                }
            }
            jQuery(this).removeAttr("onfocus"); // remove Salesforce inline js
            jQuery(this).removeAttr("onblur"); // remove Salesforce inline js
            jQuery(this).removeAttr("onmouseout"); // remove Salesforce inline js
            jQuery(this).removeAttr("onmouseover"); // remove Salesforce inline js
        });
    });
}

// nested sidebar menu
jQuery(".nested-menu li").each(function(){
    jQuery(this).has("ul").prepend('<i class="fa fa-caret-right"></i>');
});
jQuery(".nested-menu li i.fa").on("click", function(){
    if(jQuery(this).hasClass("fa-caret-right")){
        jQuery(this).removeClass("fa-caret-right");
        jQuery(this).addClass("fa-caret-down");
        jQuery(this).siblings("ul").slideDown(400);
        jQuery(this).siblings("a").css({textShadow: "0 1px 0 rgba(0,114,207, 0.55)"});
    }else if(jQuery(this).hasClass("fa-caret-down")){
        jQuery(this).removeClass("fa-caret-down");
        jQuery(this).addClass("fa-caret-right");
        jQuery(this).siblings("ul").slideUp(400);
        jQuery(this).siblings("a").css({textShadow: "0 0 0 #ffffff"});
    }
});
// if sidebar checkbox checked change text color
jQuery(".sidebar .one-panel label").on("click", function(){
    if(jQuery(this).find("input[type=checkbox]").is(":checked")){
        jQuery(this).css({color: "#2a2a2a", textShadow: "0 1px 1px #cccccc"});
    }else{
        jQuery(this).css({color: "", textShadow: "0 0 0 #ffffff"});
    }
});

// customize checkboxes
jQuery(".checkbox label input[type=checkbox], label.checkbox-inline input[type=checkbox]").each(function(){
    if(jQuery(this).is(":checked")){
        jQuery(this).parent().addClass("checked");
    }
    if(jQuery(this).is(":disabled")){
        jQuery(this).parent().addClass("disabled");
    }
    jQuery(this).click(function(){
        if(jQuery(this).is(":checked")){
            jQuery(this).parent().addClass("checked");
        }else{
            jQuery(this).parent().removeClass("checked");
        }
    });
});
// customize radiobuttons
jQuery(".radio label input[type=radio], label.radio-inline input[type=radio]").each(function(){
    if(jQuery(this).prop("checked")){
        jQuery(this).parent().addClass("checked");
    }
});
jQuery(".radio label input[type=radio], label.radio-inline input[type=radio]").each(function(){
    if(jQuery(this).prop("disabled")){
        jQuery(this).parent().addClass("disabled");
    }
});
jQuery(".radio label input[type=radio], label.radio-inline input[type=radio]").click(function(){
    if(jQuery(this).prop('checked')){
        jQuery(this).parents(".wrapper-radiobuttons").find("label").removeClass("checked");
        jQuery(this).parent().addClass("checked");
    }
});

if (navigator.userAgent.indexOf('Safari') != -1 && navigator.userAgent.indexOf('Chrome') == -1){
    jQuery("body").css({fontFamily: "Arial"});
}

// show only current datepicker and close the others
jQuery("body").on("focus", "input.datepicker", function(){
	var inputIndex = jQuery("input.datepicker").index(this);
	jQuery(".datepicker.dropdown-menu").each(function(){
		var datepickerIndex = jQuery(".datepicker.dropdown-menu").index(this);
		if(datepickerIndex != inputIndex){
			jQuery(this).css({display: "none"})
		}
	});
});
// close datepicker when click a tab
$("input, textarea, a").on("keyup", function(e){
    var keyCode = e.keyCode || e.which;

    if(keyCode == 9){
        var inputIndex = jQuery("input.datepicker").index(this);
        jQuery(".datepicker.dropdown-menu").each(function(){
            var datepickerIndex = jQuery(".datepicker.dropdown-menu").index(this);
            if(datepickerIndex != inputIndex){
                jQuery(this).css({display: "none"});
            }
        });
    }
});
//remove inline salesforse js
jQuery(function(){
	jQuery("input.datepicker").removeAttr("onfocus").removeAttr("data-uidsfdc");
});
//imitation of salesforce "span to input" behavior
jQuery(".dateInput span.dateFormat a").each(function(){
	jQuery(this).prop("href", "#");
	var linkCont = jQuery(this).text();
	jQuery(this).on("click", function(e){
		e.preventDefault();
		jQuery(this).parents(".dateInput").find("input.datepicker").val(linkCont);
	});
});
//jQuery("input.datepicker").datepicker();
jQuery("body").on("focus", "input.datepicker", function(){
	jQuery(this).datepicker();
	
	jQuery(".datepicker.dropdown-menu tbody").click(function(){
		jQuery(this).parents(".datepicker.dropdown-menu").css({display: "none"});
	});
});
