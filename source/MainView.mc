using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;

import WFSettings as S;
import SunTimes;
import Sensors;
import WeatherInfo;
import GeoInfo;
import Icons;
import HistoryGraphs;

class MainView extends Ui.WatchFace {

    function initialize() { Ui.WatchFace.initialize(); }

    function onUpdate(dc as Gfx.Dc) { draw(dc); Ui.requestUpdate(); }
    function onPartialUpdate(dc as Gfx.Dc) { draw(dc); }

    function _colors() as Dictionary {
        var fg = Gfx.COLOR_WHITE, bg = Gfx.COLOR_BLACK;
        var scheme = S.colorScheme();
        if (scheme == "light") { fg = Gfx.COLOR_BLACK; bg = Gfx.COLOR_WHITE; }
        else if (scheme == "auto") {
            if (SunTimes.isDayNow()) { fg = Gfx.COLOR_BLACK; bg = Gfx.COLOR_WHITE; }
            else { fg = Gfx.COLOR_WHITE; bg = Gfx.COLOR_BLACK; }
        }
        return { :fg=>fg, :bg=>bg };
    }

    function draw(dc as Gfx.Dc) {
        var cols = _colors(); var fg = cols[:fg]; var bg = cols[:bg];
        var w = dc.getWidth(), h = dc.getHeight();
        dc.setColor(fg, bg); dc.clear();

        var now = Time.now(); var t = Gregorian.info(now, Time.FORMAT_SHORT);

        // ===== Верхній ряд =====
        var batt = Sensors.batteryPct();
        if (S.batteryDisp() == "icon") Icons.drawBatteryFromSprites(dc, 14, 12, batt);
        else dc.drawText(14, 16, Gfx.FONT_XTINY, batt + "%", Gfx.TEXT_JUSTIFY_LEFT);

        drawTopBlock(dc, fg, bg, w);

        // ===== Час =====
        var hh = _pad2(t.hour), mm = _pad2(t.min);
        dc.drawText(w/2, 100, Gfx.FONT_LARGE, hh + ":" + mm, Gfx.TEXT_JUSTIFY_HCENTER);

        // ===== Дата =====
        var dateStr = _formatDate(t);
        dc.drawText(w/2, 138, Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_HCENTER);

        // ===== Прогрес-бар =====
        _drawProgress(dc, fg, bg, w, h);

        // ===== Нижній блок =====
        _drawBottomBlock(dc, fg, bg, w, h);

        // ===== BT-статус унизу =====
        var connected = Sensors.phoneConnected();
        Icons.drawBtIcon(dc, w/2 - 12, h - 20, connected);
        dc.drawText(w/2 + 8, h - 18, Gfx.FONT_XTINY,
            connected ? @Rez.Strings.label_connected : @Rez.Strings.label_disconnected,
            Gfx.TEXT_JUSTIFY_BASELINE);
    }

    function drawTopBlock(dc as Gfx.Dc, fg, bg, w as Number) {
        var mode = S.topMode();
        var y = 14; if (mode == "hidden") return;

        if (mode == "sun") {
            var s1 = @Rez.Strings.label_sunrise + " " + SunTimes.sunriseStr();
            var s2 = @Rez.Strings.label_sunset  + " " + SunTimes.sunsetStr();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, s1 + "  •  " + s2, Gfx.TEXT_JUSTIFY_HCENTER);
            return;
        }
        if (mode == "hr") {
            var hr = Sensors.heartRate();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, @Rez.Strings.label_hr + ": " + (hr>0?hr:"--"),
                        Gfx.TEXT_JUSTIFY_HCENTER); return;
        }
        if (mode == "stress") {
            var st = Sensors.stressLevel();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, @Rez.Strings.label_stress + ": " + (st>0?st:"--"),
                        Gfx.TEXT_JUSTIFY_HCENTER); return;
        }
        if (mode == "weather") {
            var f = WeatherInfo.forecastText();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, f, Gfx.TEXT_JUSTIFY_HCENTER); return;
        }
        if (mode == "pressure") {
            var p = Sensors.pressure_mmHg();
            var trend = Sensors.pressureTrend();
            var icon = Rez.Drawables.Trend_stable;
            if (trend == 1) icon = Rez.Drawables.Trend_up;
            else if (trend == -1) icon = Rez.Drawables.Trend_down;
            dc.drawBitmap(Gfx.createBitmap(icon), w/2 - 36, y - 8);
            dc.drawText(w/2, y, Gfx.FONT_XTINY,
                        (p>0? (p as Number).toNumber().toString().split(".")[0] : "--") + " мм рт. ст.",
                        Gfx.TEXT_JUSTIFY_HCENTER);
            return;
        }
        if (mode == "city") {
            var city = GeoInfo.cityOrNA();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, city, Gfx.TEXT_JUSTIFY_HCENTER); return;
        }

        // --- Графіки (верхній блок) ---
        var gx = 20; var gy = 30; var gw = w - 40; var gh = 60;
        if (mode == "steps_history") {
            var total = Sensors.stepsToday();
            dc.drawText(w/2, 14, Gfx.FONT_XTINY, total + " " + @Rez.Strings.label_steps, Gfx.TEXT_JUSTIFY_HCENTER);
            HistoryGraphs.drawSteps7Days(dc, gx, gy, gw, gh, fg, bg); return;
        }
        if (mode == "activity_history") {
            dc.drawText(w/2, 14, Gfx.FONT_XTINY, "активність (7д)", Gfx.TEXT_JUSTIFY_HCENTER);
            HistoryGraphs.drawActivity7Days(dc, gx, gy, gw, gh, fg, bg); return;
        }
        if (mode == "pressure_history") {
            var p2 = Sensors.pressure_mmHg();
            dc.drawText(w/2, 14, Gfx.FONT_XTINY,
                (p2>0? (p2 as Number).toNumber().toString().split(".")[0] : "--") + " мм рт. ст.",
                Gfx.TEXT_JUSTIFY_HCENTER);
            HistoryGraphs.drawPressure7Hours(dc, gx, gy, gw, gh, fg, bg); return;
        }
    }

    function _drawBottomBlock(dc as Gfx.Dc, fg, bg, w as Number, h as Number) {
        var mode = S.bottomMode(); if (mode == "hidden") return;
        var y = h - 46;

        if (mode == "sun") {
            var s1 = @Rez.Strings.label_sunrise + " " + SunTimes.sunriseStr();
            var s2 = @Rez.Strings.label_sunset  + " " + SunTimes.sunsetStr();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, s1 + "  •  " + s2, Gfx.TEXT_JUSTIFY_HCENTER);
        } else if (mode == "hr") {
            var hr = Sensors.heartRate();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, @Rez.Strings.label_hr + ": " + (hr>0?hr:"--"),
                        Gfx.TEXT_JUSTIFY_HCENTER);
        } else if (mode == "stress") {
            var st = Sensors.stressLevel();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, @Rez.Strings.label_stress + ": " + (st>0?st:"--"),
                        Gfx.TEXT_JUSTIFY_HCENTER);
        } else if (mode == "weather") {
            var f = WeatherInfo.forecastText();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, f, Gfx.TEXT_JUSTIFY_HCENTER);
        } else if (mode == "pressure") {
            var p = Sensors.pressure_mmHg();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, @Rez.Strings.label_pressure + ": " +
                        (p>0? (p as Number).toNumber().toString().split(".")[0] : "--") + " мм рт. ст.",
                        Gfx.TEXT_JUSTIFY_HCENTER);
        } else if (mode == "city") {
            var city = GeoInfo.cityOrNA();
            dc.drawText(w/2, y, Gfx.FONT_XTINY, city, Gfx.TEXT_JUSTIFY_HCENTER);
        }
    }

    function _drawProgress(dc as Gfx.Dc, fg, bg, w as Number, h as Number) {
        var mode = S.progressMode();
        var y = 162;
        var label = ""; var pct = 0.0;

        if (mode == "steps") {
            var steps = Sensors.stepsToday();
            var goal  = Sensors.stepGoal();
            pct = goal > 0 ? (100.0*steps/goal) : 0.0;
            label = "кроки " + steps + "/" + goal;
        } else if (mode == "stress") {
            var st = Sensors.stressLevel();
            pct = Math.min(100, st);
            label = "стрес " + (st>0?st:"--");
        } else if (mode == "battery") {
            var b = Sensors.batteryPct();
            pct = b; label = "батарея " + b + "%";
        } else if (mode == "active_minutes") {
            var am = Sensors.activeMinutesToday();
            pct = Math.min(100, 100.0 * am / 60.0);
            label = "активні " + am + " хв";
        }

        Icons.drawProgressBar(dc, 20, y, w-40, 12, pct, fg, bg);
        dc.drawText(w/2, y+16, Gfx.FONT_XTINY, label, Gfx.TEXT_JUSTIFY_HCENTER);
    }

    function _formatDate(t as Dictionary) as String {
        var dw = ["Нд","Пн","Вт","Ср","Чт","Пт","Сб"][t.day_of_week];
        var d  = _pad2(t.day); var m = _pad2(t.month); var y = (t.year % 100);
        var f = S.dateFormat();
        if (f == "WDM") return dw + " " + d + "." + m;
        if (f == "DMY") return d + "." + m + "." + y;
        return d + "." + m + " " + dw;
    }

    function _pad2(n as Number) as String { return n<10 ? "0"+n : n+""; }
}
