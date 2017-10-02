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

$(document).ready(function () {

    $(".batch-button").click(function () {
        if ($(this).attr("href")) {

            var ids = []
            $(".checks input:checked").each(function() {
                ids.push($(this).data("id"));
            });
            $(this).attr("href", removeParameter($(this).attr("href"), "checks"));
            if (ids.length != 0) {
                $(this).attr("href", addParameter($(this).attr("href"), "checks", ids.join(",")));
            }
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