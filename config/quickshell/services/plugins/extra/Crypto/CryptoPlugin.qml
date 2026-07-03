pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../../core"
import "../../../../services"

BasePlugin {
  id: root

  // ── Manifest ─────────────────────────────────────────────────────
  pluginId: "crypto"
  manifest: ({
    author: "herckun",
    version: "1.0",
    shellVersion: "2.0",
    name: "Crypto price",
    description: "Coin price — e.g. 'btc price'",
    icon: "coin",
    locations: [],
    icons: {},
    settings: []
  })

  // ── Internal state ───────────────────────────────────────────────
  readonly property var _ids: ({
    btc: "bitcoin", eth: "ethereum", sol: "solana", ada: "cardano", xmr: "monero",
    doge: "dogecoin", ltc: "litecoin", dot: "polkadot", bnb: "binancecoin", xrp: "ripple",
    usdt: "tether", link: "chainlink", matic: "matic-network", avax: "avalanche-2"
  })

  // ── Public API ───────────────────────────────────────────────────
  readonly property var searchProvider: ({
    id: "crypto",
    priority: 220,
    query: function(text, qid) {
      var m = (text || "").trim().toLowerCase().match(/^(?:price\s+([a-z]{2,6})|([a-z]{2,6})\s+price)$/)
      if (!m) return []
      var ticker = m[1] || m[2]
      var id = root._ids[ticker]
      if (!id) return []

      RequestService.get("https://api.coingecko.com/api/v3/simple/price?ids=" + id + "&vs_currencies=usd", function(resp) {
        var rows = []
        if (resp && resp.ok && resp.data && resp.data[id] && resp.data[id].usd !== undefined) {
          var usd = resp.data[id].usd
          rows.push({
            id: "crypto:" + id,
            label: "$" + usd.toLocaleString() + "  " + ticker.toUpperCase(),
            sublabel: id + " · USD",
            icon: "coin",
            iconKind: "symbolic",
            priority: 220,
            source: "crypto",
            groupLabel: "Crypto price",
            action: function() { ProcessPool.runDetached(["xdg-open", "https://www.coingecko.com/en/coins/" + id]) }
          })
        }
        SearchService.submit(qid, "crypto", rows)
      }, undefined)
      return []
    }
  })
}
