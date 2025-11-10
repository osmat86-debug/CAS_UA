using Toybox.Application;
using Toybox.Background;
using Toybox.Time;
using Toybox.System as Sys;
import Toybox.Lang;
// ДОДАНО: Потрібно для WatchUi.requestUpdate()
using Toybox.WatchUi;
// ВИПРАВЛЕНО: Прямий імпорт Storage для getValue/setValue
using Toybox.Application.Storage;

(:background)
class casuaApp extends Application.AppBase {

    // --- ДОДАНО: Статична змінна для доступу ---
    static var mAppInstance = null;
    // ------------------------------------------

    function initialize() {
        AppBase.initialize();
        // ВИПРАВЛЕНО: Використовуємо Storage.getValue
        if (Storage.getValue("PendingWebRequests") == null) {
            // ВИПРАВЛЕНО: Використовуємо Storage.setValue
            Storage.setValue("PendingWebRequests", {});
        }
        
        // --- ДОДАНО: Зберігаємо екземпляр ---
        mAppInstance = self;
        // ------------------------------------
    }

    // --- ДОДАНО: Статичний метод для доступу ---
    static function getAppInstance() {
        return mAppInstance;
    }
    // ----------------------------------------

    function onStart(state) { }
    function onStop(state) { }

    function getInitialView() {
        return [ new casuaView() ];
    }

    // --- ДОДАНО: Функція для реагування на зміну налаштувань ---
    function onSettingsChanged() {
        // Повідомити циферблат, що потрібно перемалюватися
        WatchUi.requestUpdate(); 
    }
    // ---------------------------------------------------------

    function getServiceDelegate() {
        return [ new BackgroundService() ];
    }

    function onBackgroundData(data) {
        // ВИПРАВЛЕНО: Використовуємо Storage.getValue
        var pending = Storage.getValue("PendingWebRequests") as Dictionary;
        if (pending == null) { pending = {}; }

        if (data != null && data instanceof Dictionary) {
            var keys = data.keys();
            if (keys.size() > 0) {
                var key = keys[0];
                var payload = data[key];
                
                if (payload instanceof Dictionary) {
                    if (payload["httpError"] == null) {
                        
                        // --- НОВА ЛОГІКА РОЗРАХУНКУ ТРЕНДУ (hPa) ---
                        var trend = 0; // За замовчуванням - стабільно
                        
                        // Використовуємо точне значення "pressureHPa"
                        var newPressureHPa = payload["pressureHPa"]; 

                        if (newPressureHPa != null) {
                            // ВИПРАВЛЕНО: 'Application.Storage' -> 'Storage'
                            var oldData = Storage.getValue("OpenWeatherMapCurrent") as Dictionary;
                            
                            // Перевіряємо, чи є старі дані і чи є в них 'pressureHPa'
                            if (oldData != null && oldData["pressureHPa"] != null) {
                                var oldPressureHPa = oldData["pressureHPa"];
                                
                                // Переконуємося, що ми порівнюємо числа (Float)
                                if (oldPressureHPa instanceof Number || oldPressureHPa instanceof Float) {
                                
                                    // Використовуємо невеликий поріг (0.1 hPa), щоб уникнути "шуму"
                                    if (newPressureHPa > (oldPressureHPa.toFloat() + 0.1)) {
                                        trend = 1;  // Тиск росте
                                    } else if (newPressureHPa < (oldPressureHPa.toFloat() - 0.1)) {
                                        trend = -1; // Тиск падає
                                    }
                                }
                            }
                        }
                        payload.put("pressureTrend", trend); // Додаємо тренд до даних
                        // --- КІНЕЦЬ НОВОЇ ЛОГІКИ ---

                        pending.remove(key);
                        // ВИПРАВЛЕНО: Використовуємо Storage.setValue
                        Storage.setValue("PendingWebRequests", pending);
                        Storage.setValue(key, payload); // Зберігаємо дані ВЖE З ТРЕНДОМ
                        Storage.setValue("LastWeatherTime", Time.now().value());
                    }
                }
            }
        }
    }

    function checkPendingWeather(lat, lon) {
        if (lat != null && lon != null) {
            // ВИПРАВЛЕНО: Використовуємо Storage.setValue
            Storage.setValue("LastLocationLat", lat);
            Storage.setValue("LastLocationLng", lon);
        }

        // ВИПРАВЛЕНО: Використовуємо Storage.getValue
        var lastUpdate = Storage.getValue("LastWeatherTime");
        var now = Time.now().value();
        
        if (lastUpdate == null || !(lastUpdate instanceof Number) || (now - lastUpdate) > 1800) {
            // ВИПРАВЛЕНО: Використовуємо Storage.getValue
            var pending = Storage.getValue("PendingWebRequests") as Dictionary;
            if (pending == null) { pending = {}; }
            
            if (pending["OpenWeatherMapCurrent"] == null) {
                 pending["OpenWeatherMapCurrent"] = true;
                 // ВИПРАВЛЕНО: Використовуємо Storage.setValue
                 Storage.setValue("PendingWebRequests", pending);
                 try {
                    var nextMoment = new Time.Moment(Time.now().value() + 1);
                    Background.registerForTemporalEvent(nextMoment);
                 } catch (e) {
                    Sys.println("Event register error: " + e.getErrorMessage());
                 }
            }
        }
    }
}