using Toybox.Position as Position;

module GeoInfo {
    function cityOrNA() as String {
        try {
            var i = Position.getInfo();
            if (i != null && i.hasField("city") && i.city != null) return i.city;
        } catch(e) {}
        return "—";
    }
}
