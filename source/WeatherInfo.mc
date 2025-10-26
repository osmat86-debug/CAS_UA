using Toybox.Weather as Weather;

module WeatherInfo {
    function forecastText() as String {
        try {
            var c = Weather.getCurrentConditions();
            if (c != null) {
                var t = c.temperature;
                var d = c.description;
                if (t != null && d != null) return d + ", " + t + "°";
                if (t != null) return t + "°";
                if (d != null) return d;
            }
        } catch(e) {}
        return "N/A";
    }
}
