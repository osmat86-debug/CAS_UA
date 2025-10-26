using Toybox.System as Sys;
using Toybox.ActivityMonitor as Act;
using Toybox.Sensor as Sensor;
using Toybox.SensorHistory as SH;

module Sensors {

    function batteryPct() as Number { return (Sys.getSystemStats().battery as Number); }

    function phoneConnected() as Boolean {
        return Sys.getDeviceSettings().phoneConnected;
    }

    function stepsToday() as Number {
        try { return Act.getInfo().steps; } catch(e) { return 0; }
    }

    function stepGoal() as Number {
        try { return Act.getDailyStepGoal(); } catch(e) { return 10000; }
    }

    function heartRate() as Number {
        try {
            var hr = Sensor.getHeartRateSensor();
            var v = (hr != null) ? hr.getHeartRate() : null;
            return v == null ? 0 : v;
        } catch(e) { return 0; }
    }

    function stressLevel() as Number {
        try {
            var info = Act.getInfo();
            if (info.hasField("stress")) return info.stress;
            if (info.hasField("stressLevel")) return info.stressLevel;
        } catch(e) {}
        return 0;
    }

    function pressure_hPa() as Number {
        try {
            var s = SH.getCurrentPressureSample();
            if (s != null && s.hasField("pressure")) return s.pressure;
        } catch(e) {}
        return 0;
    }

    function pressure_mmHg() as Number {
        var h = pressure_hPa();
        return h > 0 ? (h * 0.75006156) : 0;
    }

    function pressureTrend() as Number {
        // -1: вниз, 0: стабільно, 1: вгору
        try {
            var now = Sys.getTimer();
            var cur = SH.getCurrentPressureSample();
            var prev = SH.getPressureSample(Time.now().value() - 3600);
            if (cur != null && prev != null) {
                var d = cur.pressure - prev.pressure;
                if (d > 0.2) return 1;
                if (d < -0.2) return -1;
            }
        } catch(e) {}
        return 0;
    }

    function activeMinutesToday() as Number {
        try {
            var info = Act.getInfo();
            if (info.hasField("activeMinutes"))    return info.activeMinutes;
            if (info.hasField("intensityMinutes")) return info.intensityMinutes;
        } catch(e) {}
        return 0;
    }
}
