/**
 * plugin.js
 *
 * Copyright, Alberto Peripolli
 * Released under Creative Commons Attribution-NonCommercial 3.0 Unported License.
 *
 * Contributing: https://github.com/trippo/ResponsiveFilemanager
 */

tinymce.PluginManager.add('responsivefilemanager2', function (editor) {

    function openmanager() {
        editor.focus(true);
        var title = tinymce.util.I18n.translate('responsivefilemanager.insertUrl');
        if (typeof editor.settings.filemanager_title !== "undefined" && editor.settings.filemanager_title) {
            title = editor.settings.filemanager_title;
        }

        win = editor.windowManager.open({
            title: title,
            file: '/tinymce/insert_url',
            width: 380,
            height: 500,
            inline: 1,
            resizable: true,
            maximizable: true
        });
    }

    editor.addButton('responsivefilemanager2', {
        icon: 'browse',
        tooltip: tinymce.util.I18n.translate('responsivefilemanager.insertUrl'),
        onclick: openmanager
    });

    editor.addMenuItem('responsivefilemanager2', {
        icon: 'browse',
        text: tinymce.util.I18n.translate('responsivefilemanager.insertUrl'),
        onclick: openmanager,
        context: 'insert'
    });

});