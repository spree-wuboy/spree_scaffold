Spree.routes.<%= plural_name %>_api = "/api/v1/<%= plural_name %>";

$.fn.<%=singular_name%>_autocomplete = function (options) {
    'use strict';

    // Default options
    options = options || {};
    var multiple = typeof(this.data('multiple')) !== 'undefined' ? this.data('multiple') : typeof(options.multiple) !== 'undefined' ? options.multiple : true;
    var minimum = typeof(this.data('minimum')) !== 'undefined' ? this.data('minimum') : typeof(options.minimum) !== 'undefined' ? options.minimum : null;

    function format_<%=singular_name%>(object) {
        return Select2.util.escapeMarkup(object.<%=string_index_columns.first%>);
    }

    var all_options = {
        allowClear: true,
        minimumInputLength: minimum,
        multiple: multiple,
        placeholder: "find a <%=singular_name%>",
        initSelection: function (element, callback) {
            $.get(Spree.routes.<%= plural_name %>_api, {
                ids: element.val().split(','),
                token: Spree.api_key
            }, function (data) {
                callback(multiple ? data.<%= plural_name %> : data.<%= plural_name %>[0]);
            });
        },
        ajax: {
            url: Spree.routes.<%= plural_name %>_api,
            datatype: 'json',
            cache: true,
            data: function (term, page) {
                return {
                    q: {
                        <%=string_index_columns.join("_")%>_cont: term,
                    },
                    m: 'OR',
                    token: Spree.api_key
                };
            },
            results: function (data, page) {
                var <%= plural_name %> = data.<%= plural_name %> ? data.<%= plural_name %> : [];
                return {
                    results: <%= plural_name %>
                };
            }
        },
        formatResult: format_<%=singular_name%>,
        formatSelection: format_<%=singular_name%>
    }
    this.select2(all_options);
    return this;
};

$(document).ready(function () {
    $('.<%=singular_name%>_picker').<%=singular_name%>_autocomplete();
    $('.single_<%=singular_name%>_picker').<%=singular_name%>_autocomplete({multiple: false, minimum: <%=options[:select2_minimum] ? options[:select2_minimum] : 3%>});
});
