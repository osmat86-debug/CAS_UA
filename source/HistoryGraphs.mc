using Toybox.Graphics as Gfx;
using Toybox.ActivityMonitor as Act;
using Toybox.SensorHistory as SH;
using Toybox.Time as Time;

module HistoryGraphs {

    function drawSteps7Days(dc as Gfx.Dc, x as Number, y as Number, w as Number, h as Number, fg, bg) {
        var hist = Act.getHistory(7);
        var maxVal = 1;
        foreach (d in hist) { if (d.steps > maxVal) maxVal = d.steps; }

        var dayW = w / 7.0;
        var baseY = y + h;
        dc.setColor(fg, bg);

        for (var i=0; i<7; i++) {
            var v = hist[i].steps;
            var barH = (v / maxVal) * h;
            dc.fillRectangle(x + i*dayW + 2, baseY - barH, dayW - 4, barH);
        }

        var days = ["Пн","Вт","Ср","Чт","Пт","Сб","Нд"];
        for (var i=0; i<7; i++) {
            dc.drawText(x + i*dayW + dayW/2, baseY + 2, Gfx.FONT_XTINY, days[i],
                        Gfx.TEXT_JUSTIFY_TOP|Gfx.TEXT_JUSTIFY_HCENTER);
        }
    }

    function drawActivity7Days(dc as Gfx.Dc, x as Number, y as Number, w as Number, h as Number, fg, bg) {
        var hist = Act.getHistory(7);
        var maxVal = 1;
        foreach (d in hist) {
            var v = d.hasField("intensityMinutes") ? d.intensityMinutes
                  : d.hasField("activeMinutes")    ? d.activeMinutes
                  : d.calories;
            if (v > maxVal) maxVal = v;
        }

        var dayW = w / 7.0; var baseY = y + h;
        dc.setColor(fg, bg);

        for (var i=0; i<7; i++) {
            var src = hist[i];
            var val = src.hasField("intensityMinutes") ? src.intensityMinutes
                    : src.hasField("activeMinutes")    ? src.activeMinutes
                    : src.calories;
            var barH = (val / maxVal) * h;
            dc.fillRectangle(x + i*dayW + 2, baseY - barH, dayW - 4, barH);
        }

        var days = ["Пн","Вт","Ср","Чт","Пт","Сб","Нд"];
        for (var i=0;i<7;i++) {
            dc.drawText(x + i*dayW + dayW/2, baseY + 2, Gfx.FONT_XTINY, days[i],
                        Gfx.TEXT_JUSTIFY_TOP|Gfx.TEXT_JUSTIFY_HCENTER);
        }
    }

    function drawPressure7Hours(dc as Gfx.Dc, x as Number, y as Number, w as Number, h as Number, fg, bg) {
        var samples = [] as Array<Dictionary>;
        try {
            var now = Time.now().value();
            for (var i=6; i>=0; i--) {
                var s = SH.getPressureSample(now - i*3600);
                if (s != null) { samples.add({:p=>s.pressure}); }
            }
        } catch(e) {
            var p = 1013.0;
            try { var c = SH.getCurrentPressureSample(); if (c != null) p = c.pressure; } catch(e2){}
            for (var i=0;i<7;i++) samples.add({:p=>p});
        }

        var maxVal = 1;
        foreach (s in samples) { if (s[:p] > maxVal) maxVal = s[:p]; }

        var colW = w / 7.0; var baseY = y + h;
        dc.setColor(fg, bg);

        for (var i=0; i<7; i++) {
            var barH = (samples[i][:p] / maxVal) * h;
            dc.fillRectangle(x + i*colW + 2, baseY - barH, colW - 4, barH);
        }

        for (var i=0;i<7;i++) {
            dc.drawText(x + i*colW + colW/2, baseY + 2, Gfx.FONT_XTINY, ""+i,
                        Gfx.TEXT_JUSTIFY_TOP|Gfx.TEXT_JUSTIFY_HCENTER);
        }
    }
}
