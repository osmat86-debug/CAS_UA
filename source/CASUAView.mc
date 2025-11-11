using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time;
// ВИПРАВЛЕНО: Імпортуємо Application та Storage для роботи з налаштуваннями
using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Position as Position;
using Toybox.ActivityMonitor; 
// ДОДАНО: Потрібно для Body Battery
using Toybox.SensorHistory;
import Toybox.Lang;

class casuaView extends Ui.WatchFace {

    var sunriseStr = "--:--";
    var sunsetStr  = "--:--";
    var pressureStr = "---";
    var mCityName = "---";
    var mPressureTrend = 0;

    var sunriseIcon;
    var sunsetIcon;
    var mIsSleeping = true;

    var battIcons;
    var battIconCharge;
    var noSecondsIcon;
    
    var trendUpIcon;
    var trendDownIcon;
    var trendStableIcon;

    var stepsIcon; 

    // --- ЗМІННІ НАЛАШТУВАНЬ ---
    var pBatteryDisplayType = 1; // 0=Off, 1=Icons, 2=Percent, 3=Days
    var pShowSun = true;
    var pShowDate = true;
    var pShowPressure = true;
    var pShowSteps = true;
    var pShowCity = true;
    var pShowSeconds = true;
    var pBarType = 1; // 0=Off, 1=Steps, 2=Battery, 3=Calories, 4=Active (Week), 5=BodyBattery
    // --------------------------

    var dayOfWeekStrings = ["НЕД", "ПОН", "ВІВ", "СЕР", "ЧЕТ", "ПТН", "СУБ"];
    
    // --- КООРДИНАТИ ---
    var srIconX = 85;  var srIconY = 45;
    var srTextX = 85;  var srTextY = 50;
    var ssIconX = 175; var ssIconY = 45;
    var ssTextX = 175; var ssTextY = 50;
    
    var timeX = 112; var timeY = 128;
    var timeFont = Gfx.FONT_NUMBER_HOT;
    
    var secX = 210; var secY = 138;
    var secFont = Gfx.FONT_MEDIUM;

    var noSecIconId = Rez.Drawables.PowerIcon; 
    var noSecIconX = 230; var noSecIconY = 118; 
    
    // Позиція для тексту/іконки батареї
    var battIconX = 130; var battIconY = 25;
    var battTextX = 130; var battTextY = 25;
    var battTextFont = Gfx.FONT_SMALL;

    var stepBarX = 130; var stepBarY = 92;
    var stepBarWidth = 200; var stepBarHeight = 3;
    var stepBarSegments = 10; var stepBarSpacing = 3;
    var stepBarFillColor = Gfx.COLOR_WHITE;
    var stepBarEmptyColor = Gfx.COLOR_DK_GRAY;
    
    var dateX = 105; var dateY = 155;
    var dateFont = Gfx.FONT_LARGE;

    var pressureTextX = 210; var pressureTextY = 162; 
    var pressureTextFont = Gfx.FONT_SMALL;
    var pressureTrendIconX = 210; var pressureTrendIconY = 200; 
    
    var stepsIconX = 70; var stepsIconY = 210; 
    var stepsTextX = 100; var stepsTextY = 210; 
    var stepsTextFont = Gfx.FONT_SMALL;
    
    var statusX = 12; var statusY = 130; 
    var statusFont = Gfx.FONT_TINY;
    
    var cityX = 130; var cityY = 225; 
    var cityFont = Gfx.FONT_TINY;

    function initialize() {
        Ui.WatchFace.initialize();
        mIsSleeping = true;
    }

    function onLayout(dc) {
        sunriseIcon = Ui.loadResource(Rez.Drawables.SunriseIcon);
        sunsetIcon  = Ui.loadResource(Rez.Drawables.SunsetIcon);
        noSecondsIcon = Ui.loadResource(noSecIconId);

        battIconCharge = Ui.loadResource(Rez.Drawables.BattCharge);
        battIcons = [
            Ui.loadResource(Rez.Drawables.Batt20),
            Ui.loadResource(Rez.Drawables.Batt40),
            Ui.loadResource(Rez.Drawables.Batt60),
            Ui.loadResource(Rez.Drawables.Batt80),
            Ui.loadResource(Rez.Drawables.Batt100)
        ];
        trendUpIcon = Ui.loadResource(Rez.Drawables.TrendUp);
        trendDownIcon = Ui.loadResource(Rez.Drawables.TrendDown);
        trendStableIcon = Ui.loadResource(Rez.Drawables.TrendStable);

        stepsIcon = Ui.loadResource(Rez.Drawables.StepsIcon);
    }

    function onShow() {
        loadSettings(); // Оновлюємо налаштування при кожному показі
        requestSunUpdate();
    }

    // --- ФУНКЦІЯ: Завантаження налаштувань (ПОВНІСТЮ ВИПРАВЛЕНА) ---
    function loadSettings() {
        try {
            pBatteryDisplayType = getNumericSetting("BatteryDisplayType", 1);
            pBarType = getNumericSetting("BarType", 1);

            pShowSun = getBooleanSetting("ShowSun", true);
            pShowDate = getBooleanSetting("ShowDate", true);
            pShowPressure = getBooleanSetting("ShowPressure", true);
            pShowSteps = getBooleanSetting("ShowSteps", true);
            pShowCity = getBooleanSetting("ShowCity", true);
            pShowSeconds = getBooleanSetting("ShowSeconds", true);
        } catch (e) {
            Sys.println("loadSettings ERROR: " + e.getErrorMessage());
            setDefaultSettings();
        }
    }

    function getNumericSetting(key, fallback) {
        var value = getSettingValue(key);

        if (value instanceof Number) {
            return value;
        } else if (value instanceof String) {
            try {
                return value.toNumber();
            } catch (ex) {
                Sys.println("Invalid numeric setting " + key + ": " + value);
            }
        }

        return fallback;
    }

    function getBooleanSetting(key, fallback) {
        var value = getSettingValue(key);

        if (value instanceof Boolean) {
            return value;
        } else if (value instanceof Number) {
            return value != 0;
        } else if (value instanceof String) {
            if (value == "true" || value == "TRUE" || value == "True" || value == "1") {
                return true;
            } else if (value == "false" || value == "FALSE" || value == "False" || value == "0") {
                return false;
            }
        }

        return fallback;
    }

    function getSettingValue(key) {
        var value = Storage.getValue(key);

        if (value == null) {
            var app = Application.getApp();
            if (app != null) {
                value = app.getProperty(key);
            }
        }

        return value;
    }

    function setDefaultSettings() {
        pBatteryDisplayType = 1;
        pShowSun = true;
        pShowDate = true;
        pShowPressure = true;
        pShowSteps = true;
        pShowCity = true;
        pShowSeconds = true;
        pBarType = 1;
    }
    // ---------------------------------------------

    function onExitSleep() {
        mIsSleeping = false;
    }

    function onEnterSleep() {
        mIsSleeping = true;
        Ui.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        
        // ВИКЛИКАЄМО loadSettings() ТУТ, щоб реагувати на зміни
        // (onSettingsChanged викличе onUpdate, а onUpdate завантажить нові значення)
        loadSettings();
        
        updateAllWeatherData(); 
        
        // Малюємо блоки тільки якщо вони увімкнені в налаштуваннях
        if (pShowSun) { drawSunInfo(dc); }
        
        // Прогрес бар (0 = Вимкнено)
        if (pBarType > 0) { drawProgressBar(dc); }
        
        drawStatusInfo(dc); // Статус малюємо завжди
        drawClock(dc);
        
        // Батарея (0 = Вимкнено)
        if (pBatteryDisplayType > 0) { drawBattery(dc); }
        
        if (pShowDate) { drawDate(dc); }
        if (pShowPressure) { drawPressure(dc); }
        if (pShowSteps) { drawStepsInfo(dc); }
        if (pShowCity) { drawCityName(dc); }
    }

    // --- Функції малювання ---

    function drawSunInfo(dc) {
        drawSunIcon(dc, srIconX, srIconY, true);
        drawSunIcon(dc, ssIconX, ssIconY, false);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(srTextX, srTextY, Gfx.FONT_MEDIUM, sunriseStr, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(ssTextX, ssTextY, Gfx.FONT_MEDIUM, sunsetStr, Gfx.TEXT_JUSTIFY_CENTER);
    }

    function drawSunIcon(dc, x, y, isSunrise) {
        var icon = isSunrise ? sunriseIcon : sunsetIcon;
        if (icon != null) {
            dc.drawBitmap(x - icon.getWidth() / 2, y - icon.getHeight() / 2, icon);
        }
    }

    // Універсальна функція Прогрес Бару
    function drawProgressBar(dc) {
        var current = 0.0;
        var goal = 1.0;
        
        if (pBarType == 1) { // 1. КРОКИ
            var info = ActivityMonitor.getInfo();
            if (info != null && info.steps != null) {
                current = info.steps;
                if (info.stepGoal != null && info.stepGoal > 0) {
                    goal = info.stepGoal;
                }
            }
        } 
        else if (pBarType == 2) { // 2. БАТАРЕЯ
             var stats = Sys.getSystemStats();
             current = stats.battery;
             goal = 100.0;
        }
        else if (pBarType == 3) { // 3. КАЛОРІЇ
            var info = ActivityMonitor.getInfo();
            if (info != null && info.calories != null) {
                current = info.calories;
                // ВИПРАВЛЕНО: .caloriesGoal не існує в SDK 3.2. Використовуємо 2000.
                goal = 2000.0; 
            }
        }
        else if (pBarType == 4) { // 4. ХВИЛИНИ АКТИВНОСТІ (ТИЖДЕНЬ)
            var info = ActivityMonitor.getInfo();
            if (info != null && info.activeMinutesWeek != null && info.activeMinutesWeek.total != null) {
                current = info.activeMinutesWeek.total;
                goal = 150.0; // Використовуємо 150
            }
        }
        else if (pBarType == 5) { // 5. BODY BATTERY
            if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
                var bbIterator = SensorHistory.getBodyBatteryHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
                if (bbIterator != null) {
                    var lastSample = bbIterator.next();
                    if (lastSample != null && lastSample.data != null) {
                        current = lastSample.data;
                        goal = 100.0;
                    }
                }
            }
        }

        var progress = 0.0;
        if (goal > 0) { // Запобігаємо діленню на нуль
             progress = current.toFloat() / goal.toFloat();
        }
        if (progress > 1.0) { progress = 1.0; }

        var segmentsToFill = (progress * stepBarSegments).toNumber();
        var totalSpacing = stepBarSpacing * (stepBarSegments - 1);
        var totalSegmentWidth = stepBarWidth - totalSpacing;
        var segmentWidth = totalSegmentWidth / stepBarSegments;
        var startX = stepBarX - (stepBarWidth / 2);

        for (var i = 0; i < stepBarSegments; i++) {
            var currentX = startX + (i * (segmentWidth + stepBarSpacing));
            if (i < segmentsToFill) {
                dc.setColor(stepBarFillColor, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(stepBarEmptyColor, Gfx.COLOR_TRANSPARENT);
            }
            dc.fillRectangle(currentX, stepBarY - (stepBarHeight / 2), segmentWidth, stepBarHeight);
        }
    }

    function drawStatusInfo(dc) {
        var settings = Sys.getDeviceSettings();
        var statusStr = ""; 
        var inLowPower = (settings has :lowPowerMode) ? settings.lowPowerMode : false;

        if (inLowPower) {
            statusStr = "E";
        } else if (settings.phoneConnected) {
            statusStr = "P";
        } else {
            statusStr = "T";
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(statusX, statusY, statusFont, statusStr, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    function drawClock(dc) {
        var clockTime = Sys.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(timeX, timeY, timeFont, timeStr, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        
        if (!mIsSleeping && pShowSeconds) { // Враховуємо налаштування секунд
            var secondsStr = clockTime.sec.format("%02d");
            dc.drawText(secX, secY, secFont, secondsStr, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
        } else {
            if (noSecondsIcon != null) {
                dc.drawBitmap(noSecIconX - noSecondsIcon.getWidth()/2, noSecIconY - noSecondsIcon.getHeight()/2, noSecondsIcon);
            }
        }
    }

    function drawBattery(dc) {
        var stats = Sys.getSystemStats();
        
        if (pBatteryDisplayType == 1) { // 1. ІКОНКИ
            var battLevel = stats.battery;
            var isCharging = stats.charging;
            var icon = null;
            var icons = battIcons as Array;
            if (isCharging) {
                icon = battIconCharge;
            } else if (battLevel > 80) { icon = icons[4];
            } else if (battLevel > 60) { icon = icons[3];
            } else if (battLevel > 40) { icon = icons[2];
            } else if (battLevel > 20) { icon = icons[1];
            } else { icon = icons[0]; }

            if (icon != null) {
                dc.drawBitmap(battIconX - icon.getWidth()/2, battIconY - icon.getHeight()/2, icon);
            }
        }
        else if (pBatteryDisplayType == 2) { // 2. ВІДСОТКИ
            var battLevel = stats.battery;
            var battStr = battLevel.format("%d") + "%";
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(battTextX, battTextY, battTextFont, battStr, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
        else if (pBatteryDisplayType == 3) { // 3. ДНІ
            var battDays = stats.batteryInDays;
            var battStr = (battDays != null) ? battDays.format("%d") + "d" : "--d";
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(battTextX, battTextY, battTextFont, battStr, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
    }

    function drawDate(dc) {
        var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dayOfWeekStr = (dayOfWeekStrings as Array)[today.day_of_week - 1];
        var dateStr = Lang.format("$1$-$2$-$3$", [today.day.format("%02d"), dayOfWeekStr, today.month.format("%02d")]);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dateX, dateY, dateFont, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
    }

    function drawPressure(dc) {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(pressureTextX, pressureTextY, pressureTextFont, pressureStr, Gfx.TEXT_JUSTIFY_CENTER);
        
        var trendIcon = null;
        if (mPressureTrend == 1) { trendIcon = trendUpIcon; }
        else if (mPressureTrend == -1) { trendIcon = trendDownIcon; }
        else { trendIcon = trendStableIcon; }

        if (trendIcon != null) {
            dc.drawBitmap(pressureTrendIconX - trendIcon.getWidth()/2, pressureTrendIconY - trendIcon.getHeight()/2, trendIcon);
        }
    }

    function drawStepsInfo(dc) {
        var info = ActivityMonitor.getInfo();
        var steps = (info != null && info.steps != null) ? info.steps : 0;
        var stepsStr = steps.format("%d");
        if (stepsIcon != null) {
            dc.drawBitmap(stepsIconX - stepsIcon.getWidth()/2, stepsIconY - stepsIcon.getHeight()/2, stepsIcon);
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(stepsTextX, stepsTextY, stepsTextFont, stepsStr, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    function drawCityName(dc) {
        if (mCityName != null) {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cityX, cityY, cityFont, mCityName, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }

    // --- Функції оновлення даних ---

    function updateAllWeatherData() {
        var owm = Storage.getValue("OpenWeatherMapCurrent") as Dictionary;
        if (owm != null) {
            if (owm["sunrise"] != null) { sunriseStr = formatTime(owm["sunrise"]); }
            if (owm["sunset"] != null) { sunsetStr = formatTime(owm["sunset"]); }
            if (owm["pressure"] != null) { pressureStr = owm["pressure"].format("%d"); }
            if (owm["pressureTrend"] != null) { mPressureTrend = owm["pressureTrend"] as Number; }
            if (owm["cityName"] != null) { mCityName = owm["cityName"] as String; } else { mCityName = "---"; }
        }
    }
    
    function requestSunUpdate() {
        var posInfo = Position.getInfo();
        if (posInfo != null && posInfo.position != null) {
            var coords = posInfo.position.toDegrees();
            if (coords != null && coords.size() == 2) {
                var lat = coords[0]; var lon = coords[1];
                if (lat instanceof Float || lat instanceof Double) {
                    if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180 && (lat != 0.0 || lon != 0.0)) {
                        try {
                            // Тепер цей виклик спрацює
                             var app = Application.getApp();
                             if (app has :checkPendingWeather) { app.checkPendingWeather(lat, lon); }
                        } catch(e) { }
                    }
                }
            }
        }
    }

    function formatTime(epoch) {
         if (epoch == null || !(epoch instanceof Number || epoch instanceof Long)) { return "--:--"; }
        var m = new Time.Moment(epoch);
        var info = Time.Gregorian.info(m, Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }
}