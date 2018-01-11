// history stuff

define_browser_object_class(
    "history-url", null,
    function (I, prompt) {
        check_buffer (I.buffer, content_buffer);
        var result = yield I.buffer.window.minibuffer.read_url(
            $prompt = prompt,  $use_webjumps = false, $use_history = true, $use_bookmarks = false);
        yield co_return (result);
    });

interactive("find-url-from-history",
            "Find a page from history in the current buffer",
            "find-url",
            $browser_object = browser_object_history_url);

interactive("find-url-from-history-new-buffer",
            "Find a page from history in the current buffer",
            "find-url-new-buffer",
            $browser_object = browser_object_history_url);

interactive("toggle-stylesheets",
            "Toggle whether conkeror uses style sheets (CSS) for the " +
            "current buffer.  It is sometimes useful to turn off style " +
            "sheets when the web site makes obnoxious choices.",
            function(I) {
  var s = I.buffer.document.styleSheets;
  for (var i = 0; i < s.length; i++)
    s[i].disabled = !s[i].disabled;
});