pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../system"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property string weather: "N/A"
  property string temp: "--"
  property int weatherCode: -1
  property bool loaded: false
  property string location: "Unknown"
  property string countryCode: ""
  property bool hasData: false

  property string feelsLike: "--"
  property string humidity: "--"
  property string windSpeed: "--"
  property string windDir: ""
  property string pressure: "--"
  property string uvIndex: "--"
  property string sunrise: "--"
  property string sunset: "--"
  property string precip: "0"

  property real latitude: 0
  property real longitude: 0

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function wmoDescription(code: int): string {
    if (code === 0) return "Clear sky"
    if (code <= 3) return "Partly cloudy"
    if (code <= 49) return "Fog"
    if (code <= 59) return "Drizzle"
    if (code <= 69) return "Rain"
    if (code <= 79) return "Snow"
    if (code <= 82) return "Rain showers"
    if (code <= 86) return "Snow showers"
    if (code <= 99) return "Thunderstorm"
    return "Unknown"
  }

  function wmoIcon(code: int): string {
    if (code === 0) return "☀"
    if (code <= 3) return "☁"
    if (code <= 49) return "☾"
    if (code <= 59) return "☂"
    if (code <= 69) return "☂"
    if (code <= 79) return "❄"
    if (code <= 82) return "☂"
    if (code <= 86) return "❄"
    if (code <= 99) return "⚡"
    return "☀"
  }

  function windDirection(deg: int): string {
    var dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    return dirs[Math.round(deg / 22.5) % 16]
  }

  function fetch(): void {
    ProcessPool.runTracked("Geo locate", "timeout 5 curl -s 'https://ipinfo.io/json'", {
      id: "geo-locate",
      shell: true,
      callback: function(r) {
        try {
          var j = JSON.parse(r.stdout)
          var loc = j.loc.split(",")
          svc.latitude = parseFloat(loc[0])
          svc.longitude = parseFloat(loc[1])
          svc.location = j.city || ""
          svc.countryCode = j.country || ""
        } catch (e) {
          svc.latitude = 48.8566
          svc.longitude = 2.3522
          svc.location = "Paris"
        }
        svc._fetchWeather()
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  readonly property int _baseFetchInterval: 1800000
  readonly property int _baseInitialFetchInterval: 5000

  readonly property int _fetchInterval: PerformanceService.scaleInterval(_baseFetchInterval)
  readonly property int _initialFetchInterval: PerformanceService.scaleInterval(_baseInitialFetchInterval)

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _fetchWeather(): void {
    var url = "https://api.open-meteo.com/v1/forecast?" +
      "latitude=" + svc.latitude + "&longitude=" + svc.longitude +
      "&current=temperature_2m,relative_humidity_2m,apparent_temperature," +
      "precipitation,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure" +
      "&daily=sunrise,sunset,uv_index_max" +
      "&timezone=auto&forecast_days=1"

    ProcessPool.runTracked("Fetch weather", "timeout 8 curl -s '" + url + "'", {
      id: "fetch-weather",
      shell: true,
      callback: function(r) {
        try {
          var j = JSON.parse(r.stdout)
          var c = j.current
          var d = j.daily

          svc.temp = Math.round(c.temperature_2m) + "°"
          svc.weatherCode = c.weather_code
          svc.weather = svc.wmoDescription(c.weather_code)
          svc.feelsLike = Math.round(c.apparent_temperature) + "°"
          svc.humidity = c.relative_humidity_2m + "%"
          svc.windSpeed = Math.round(c.wind_speed_10m) + " km/h"
          svc.windDir = svc.windDirection(c.wind_direction_10m)
          svc.pressure = Math.round(c.surface_pressure) + " hPa"
          svc.precip = c.precipitation + " mm"

          if (d && d.uv_index_max) svc.uvIndex = d.uv_index_max[0].toFixed(1)
          if (d && d.sunrise) svc.sunrise = d.sunrise[0].substring(11, 16)
          if (d && d.sunset) svc.sunset = d.sunset[0].substring(11, 16)

          svc.hasData = true
          svc.loaded = true
        } catch (e) {
          svc.loaded = true
        }
      }
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  SYSTEM INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  SIGNAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  Timer {
    interval: svc._fetchInterval
    running: true
    repeat: true
    onTriggered: svc.fetch()
  }

  Timer {
    interval: svc._initialFetchInterval
    running: true
    repeat: false
    onTriggered: svc.fetch()
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  Component.onCompleted: {
  }
}
