using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class App extends App.AppBase {
    function initialize() { App.AppBase.initialize(); }
    function onStart(state) { }
    function getInitialView() { return [ new MainView() ]; }
    function onStop(state) { }
}
