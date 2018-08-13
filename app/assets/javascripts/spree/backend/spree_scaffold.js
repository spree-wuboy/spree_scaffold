//= require tinymce
//= require tinymce/dropzone
//= require tinymce/insert
//= require tinymce/plugins
//= require spree/backend/jquery_ujs.prompt

function removeParameter(url, parameterName) {
    var rtn = url.split("?")[0],
        param,
        params_arr = [],
        queryString = (url.indexOf("?") !== -1) ? url.split("?")[1] : "";
    if (queryString !== "") {
        params_arr = queryString.split("&");
        for (var i = params_arr.length - 1; i >= 0; i -= 1) {
            param = params_arr[i].split("=")[0];
            if (param === parameterName) {
                params_arr.splice(i, 1);
            }
        }
        rtn = rtn + "?" + params_arr.join("&");
    }
    return rtn;
}

function addParameter(url, parameterName, parameterValue, atStart/*Add param before others*/){
    replaceDuplicates = true;
    if(url.indexOf('#') > 0){
        var cl = url.indexOf('#');
        urlhash = url.substring(url.indexOf('#'),url.length);
    } else {
        urlhash = '';
        cl = url.length;
    }
    sourceUrl = url.substring(0,cl);

    var urlParts = sourceUrl.split("?");
    var newQueryString = "";

    if (urlParts.length > 1)
    {
        var parameters = urlParts[1].split("&");
        for (var i=0; (i < parameters.length); i++)
        {
            var parameterParts = parameters[i].split("=");
            if (!(replaceDuplicates && parameterParts[0] == parameterName))
            {
                if (newQueryString == "")
                    newQueryString = "?";
                else
                    newQueryString += "&";
                newQueryString += parameterParts[0] + "=" + (parameterParts[1]?parameterParts[1]:'');
            }
        }
    }
    if (newQueryString == "")
        newQueryString = "?";

    if(atStart){
        newQueryString = '?'+ parameterName + "=" + parameterValue + (newQueryString.length>1?'&'+newQueryString.substring(1):'');
    } else {
        if (newQueryString !== "" && newQueryString != '?')
            newQueryString += "&";
        newQueryString += parameterName + "=" + (parameterValue?parameterValue:'');
    }
    return urlParts[0] + newQueryString + urlhash;
};

$.fn.select2Autocomplete = function (options) {
    'use strict';

    // Default options
    options = options || {};
    var multiple = typeof(options.multiple) !== 'undefined' ? options.multiple : true;

    function formatSelect2(data) {
        if (options.name.indexOf(".") != -1) {
            var dd = data, names = options.name.split(".");
            for (var i=0;i<names.length; i++) {
                dd = dd[names[i]];
            }
            return Select2.util.escapeMarkup(dd || data["id"]);
        } else {
            return Select2.util.escapeMarkup(data[options.name || "id"]);
        }
    }

    this.select2({
        minimumInputLength: options["minimum-input-length"] || 3,
        multiple: multiple,
        initSelection: function (element, callback) {
            $.get(options.url, {
                ids: element.val().split(','),
                token: Spree.api_key
            }, function (data) {
                callback(multiple ? data[options.objects] : data[options.objects][0]);
            });
        },
        ajax: {
            url: options.url,
            datatype: 'json',
            cache: true,
            data: function (term, page) {
                var q = {}
                q[options.query || "id_cont"] = term;
                return {
                    q: q,
                    m: 'OR',
                    token: Spree.api_key
                };
            },
            results: function (data, page) {
                var objects = data[options.objects] ? data[options.objects] : [];
                return {
                    results: objects
                };
            }
        },
        formatResult: formatSelect2,
        formatSelection: formatSelect2
    });
};

$(document).ready(function () {


    tinymce.init({
        content_css: css_path,
        language: 'en',
        selector: ".tinymce-div",
        plugins: "link advlist code autolink table lists colorpicker insertdatetime wordcount charmap autolink hr anchor pagebreak textcolor responsivefilemanager responsivefilemanager2 youtube localautosave preview mobilepreview",
        toolbar1: "undo redo |  bullist numlist outdent indent | image media | responsivefilemanager responsivefilemanager2 | youtube | localautosave | preview mobilepreview",
        toolbar2: "styleselect | bold italic underline | fontsizeselect forecolor backcolor",
        plugin_preview_width: 1000,
        relative_urls: false,
        setup: function (ed) {
            ed.on('keydown',function(e) {
                if(e.keyCode == 13){
                    if(ed.dom.hasClass(ed.selection.getNode(), 'youtube')){
                        ed.selection.setContent('<div>&nbsp;</div>');
                        return false;
                    } else {
                        return true;
                    }
                }
            });
        }
    });


    $('.select2-picker').each(function() {
        if ($(this).parents(".nested-template").length == 0) {
            $(this).select2Autocomplete($(this).data());
        }
    });

    $(".batch-button").click(function () {
        if ($(this).attr("href")) {
            $(this).attr("href", addParameter($(this).attr("href"), "checked", true));
        }
    });
    $(".nested-template").hide().find("input, select, textarea").prop("disabled", true)
    var subFieldId = 0;
    $('.spree_add_sub_fields').click(function () {
        var target = $(this).data("target");
        var new_table_row = $("#" + target + "-template").clone();
        var appender = $("#" + target + "-tbody");
        new_table_row.show().find("input, select, textarea").prop("disabled", false);
        var new_id = new Date().getTime() + (subFieldId++);
        new_table_row.find("input, select").each(function () {
            var el = $(this);
            el.prop("id", el.prop("id").replace(/\d+/, new_id))
            el.prop("name", el.prop("name").replace(/\d+/, new_id))
        })
        // When cloning a new row, set the href of all icons to be an empty "#"
        // This is so that clicking on them does not perform the actions for the
        // duplicated row
        new_table_row.find("a").each(function () {
            var el = $(this);
            el.prop('href', '#');
        })
        appender.append(new_table_row);
        new_table_row.find('.select2-picker').each(function() {
            $(this).select2Autocomplete($(this).data());
        });
    });

    $('body').on('click', 'a.spree_remove_sub_fields', function () {
        el = $(this);

        if (el.parents("table").find('a.spree_remove_sub_fields').length == 1) {
            el.parents("tr").find("input").val("");
        } else {
            el.closest(".fields").hide();
            if (el.prop("href").substr(-1) == '#') {
                el.parents("tr").fadeOut('hide', function () {
                    var name = $(this).find("[name$='[id]']").attr("name").replace("[id]", "") + "[_destroy]"
                    $(this).append($("<input type='hidden' name='" + name + "' value='1'/>"));
                });
            } else if (el.prop("href")) {
                $.ajax({
                    type: 'POST',
                    url: el.prop("href"),
                    data: {
                        _method: 'delete',
                        authenticity_token: AUTH_TOKEN
                    },
                    success: function (response) {
                        el.parents("tr").fadeOut('hide');
                    },
                    error: function (response, textStatus, errorThrown) {
                        show_flash('error', response.responseText);
                    }

                })
            }
        }
        return false;
    });
});