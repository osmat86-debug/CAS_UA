using Toybox.Graphics as Gfx;

module Icons {

    function drawBatteryFromSprites(dc as Gfx.Dc, x as Number, y as Number, pct as Number) {
        var bmp;
        if (pct < 15) bmp = Rez.Drawables.Battery_0;
        else if (pct < 40) bmp = Rez.Drawables.Battery_25;
        else if (pct < 65) bmp = Rez.Drawables.Battery_50;
        else if (pct < 90) bmp = Rez.Drawables.Battery_75;
        else bmp = Rez.Drawables.Battery_100;
        dc.drawBitmap(Gfx.createBitmap(bmp), x, y);
    }

    function drawBtIcon(dc as Gfx.Dc, x as Number, y as Number, connected as Boolean) {
        var bmp = connected ? Rez.Drawables.bt_on : Rez.Drawables.bt_off;
        dc.drawBitmap(Gfx.createBitmap(bmp), x, y);
    }

    function drawProgressBar(dc as Gfx.Dc, x as Number, y as Number, w as Number, h as Number, pct as Number, fg, bg) {
        dc.setColor(fg, bg);
        dc.drawRoundedRectangle(x, y, w, h, 4);
        var fill = (w-2) * Math.max(0, Math.min(1, pct/100.0));
        dc.fillRoundedRectangle(x+1, y+1, fill, h-2, 3);
    }
}
