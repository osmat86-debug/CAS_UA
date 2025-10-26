using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Position as Position;
using Toybox.Weather as Weather;

module SunTimes {
    var _sunrise as Time.Moment or Null = null;
    var _sunset  as Time.Moment or Null = null;
    var _day = -1;

    function _update() {
        var now = Time.now();
        var d = Gregorian.info(now, Time.FORMAT_SHORT).day;
        if (d == _day && _sunrise != null && _sunset != null) return;

        var info = Position.getInfo();
        if (info != null && info.position != null) {
            try {
                _sunrise = Weather.getSunrise(info.position, now);
                _sunset  = Weather.getSunset(info.position, now);
                _day = d;
            } catch(e) {
                _sunrise = null; _sunset = null; _day = -1;
            }
        }
    }

    function sunriseStr() as String {
        _update();
        if (_sunrise == null) return "--:--";
        var i = Gregorian.info(_sunrise, Time.FORMAT_SHORT);
        return _pad2(i.hour) + ":" + _pad2(i.min);
    }

    function sunsetStr() as String {
        _update();
        if (_sunset == null) return "--:--";
        var i = Gregorian.info(_sunset, Time.FORMAT_SHORT);
        return _pad2(i.hour) + ":" + _pad2(i.min);
    }

    function isDayNow() as Boolean {
        _update();
        if (_sunrise == null || _sunset == null) return true;
        var now = Time.now().value();
        return (now >= _sunrise.value() && now < _sunset.value());
    }

    function _pad2(n as Number) as String { return n < 10 ? "0"+n : n+""; }
}
