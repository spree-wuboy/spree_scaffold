$(document).ready(function() {
    $(".nested-template").hide().find("input, select, textarea").prop( "disabled", true )
    var subFieldId = 0;
    $('.spree_add_sub_fields').click(function () {
        var target = $(this).data("target");
        var new_table_row = $("#" + target + "-template").clone();
        var appender =  $("#" + target + "-tbody");
        new_table_row.show().find("input, select, textarea").prop( "disabled", false );
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

    $('body').on('click', 'a.spree_remove_sub_fields', function() {
        el = $(this);

        if ( el.parents("table").find('a.spree_remove_sub_fields').length == 1) {
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