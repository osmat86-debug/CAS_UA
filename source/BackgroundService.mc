using Toybox.Background;
using Toybox.System as Sys;
using Toybox.Communications as Comms;
using Toybox.Application.Storage;
using Toybox.Application;
import Toybox.Lang;

(:background)
class BackgroundService extends Sys.ServiceDelegate {

    function initialize() {
        Sys.ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
       var lat = Storage.getValue("LastLocationLat");
        var lon = Storage.getValue("LastLocationLng");

        if (lat == null || lon == null) {
            Background.exit({});
            return;
        }

        // ВАШ API КЛЮЧ
        var apiKey = "333d6a4283794b870f5c717cc48890b5"; 

        makeWebRequest(
            "https://api.openweathermap.org/data/2.5/weather",
            {
                "lat"   => lat.toFloat(),
                "lon"   => lon.toFloat(),
                "appid" => apiKey,
                "units" => "metric" // 'metric' дає тиск у hPa
            },
            method(:onReceiveOWM)
        );
    }

    function onReceiveOWM(code, data) {
        var result = {};
        Sys.println("BG: OWM Response code: " + code); 

        if (code == 200 && data instanceof Dictionary) {
            var sysBlk = data["sys"];
            var mainBlk = data["main"];
            var cityName = null;

            var sunrise = null;
            var sunset = null;
            var pressureMmHg = null;

            if (sysBlk instanceof Dictionary) {
                sunrise = sysBlk["sunrise"];
                sunset  = sysBlk["sunset"];
            }
            
            if (mainBlk instanceof Dictionary) {
                var pressureHPa = mainBlk["pressure"]; 
                if (pressureHPa != null) {
                    // ЗБЕРІГАЄМО ТОЧНЕ ЗНАЧЕННЯ ДЛЯ РОЗРАХУНКУ ТРЕНДУ
                    result["pressureHPa"] = pressureHPa.toFloat();
                    
                    // Конвертуємо в мм рт.ст. для відображення
                    pressureMmHg = (pressureHPa * 0.750062).toNumber();
                    Sys.println("BG: Pressure " + pressureHPa + " hPa -> " + pressureMmHg + " mmHg");
                }
            }
            
            if (data["name"] != null) {
                cityName = data["name"] as String;
            }

            result.put("sunrise", sunrise);
            result.put("sunset", sunset);
            result.put("pressure", pressureMmHg); // Це для відображення (в mmHg)
            result.put("cityName", cityName);

        } else {
            result = { "httpError" => code };
        }

        Background.exit({ "OpenWeatherMapCurrent" => result });
    }

    function makeWebRequest(url, params, cb) {
        var opts = {
            :method => Comms.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comms.REQUEST_CONTENT_TYPE_URL_ENCODED },
            :responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Comms.makeWebRequest(url, params, opts, cb);
    }
}
