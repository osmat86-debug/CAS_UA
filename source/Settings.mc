using Toybox.Application as App;

module WFSettings {
    function _get(id as String, def as String) as String {
        try { var v = App.getApp().getProperty(id); if (v != null) return v; } catch(e) {}
        return def;
    }
    function topMode()       as String { return _get("topBlockMode", "sun"); }
    function bottomMode()    as String { return _get("bottomBlockMode", "city"); }
    function dateFormat()    as String { return _get("dateFormat", "DMW"); }
    function progressMode()  as String { return _get("progressBarMode", "steps"); }
    function batteryDisp()   as String { return _get("batteryDisplay", "icon"); }
    function colorScheme()   as String { return _get("colorScheme", "dark"); }
}
