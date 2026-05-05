import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:frontend/models/settings.dart';

String openWebullEditor(String stock) {
  return """
(async () => {
const symbol = "${stock}";
console.log("this is the stock")
console.log(symbol)
/** Wait up to `timeout` ms for `fn()` to return a truthy value. */
  function waitFor(fn, timeout = 5000, interval = 100) {
    return new Promise((resolve, reject) => {
      const start = Date.now();
      const id = setInterval(() => {
        const result = fn();
        if (result) {
          clearInterval(id);
          resolve(result);
        } else if (Date.now() - start >= timeout) {
          clearInterval(id);
          reject(new Error(`waitFor timed out after \${timeout}ms`));
        }
      }, interval);
    });
  }

  /** Simulate a realistic user typing into an input (works with React-controlled inputs). */
  function nativeInputValue(el, value) {
    const nativeInputValueSetter = Object.getOwnPropertyDescriptor(
      window.HTMLInputElement.prototype,
      "value"
    ).set;
    nativeInputValueSetter.call(el, value);
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
  }

  // ── Step 1: Find the search input ─────────────────────────────────────────

  console.log(`[searchStock] Waiting for search bar to mount…`);

  // Try common selectors; adjust if the site uses a different attribute.
  const SEARCH_SELECTORS = [
    'input[placeholder*="Symbol"]',
    'input[placeholder*="symbol"]',
    'input[placeholder*="Name"]',
    'input[placeholder*="name"]',
    'input[aria-label*="Symbol"]',
    'input[aria-label*="symbol"]',
    'input[aria-label*="Name"]',
  ];

  const searchInput = await waitFor(() => {
    for (const sel of SEARCH_SELECTORS) {
      const el = document.querySelector(sel);
      if (el) {
        console.log(`[searchStock] Found input with selector: \${sel}`);
        return el;
      }
    }
    return null;
  }, 15000, 100);

  // ── Step 2: Focus + type the symbol ───────────────────────────────────────

  searchInput.focus();
  searchInput.click();

  // Clear any existing value first
  nativeInputValue(searchInput, "");
  await new Promise(r => setTimeout(r, 100));

  // Set the symbol value and trigger React's synthetic events
  nativeInputValue(searchInput, symbol.toUpperCase());

  // Also dispatch a keydown/keyup sequence so autocomplete hooks fire
  ["keydown", "keypress", "keyup"].forEach(type => {
    searchInput.dispatchEvent(new KeyboardEvent(type, { bubbles: true, key: symbol.slice(-1) }));
  });

  console.log(`[searchStock] Typed "\${symbol.toUpperCase()}" into search bar.`);

  // ── Step 3: Wait for the dropdown option with matching ticker ──────────────

  console.log(`[searchStock] Waiting for dropdown…`);

  const targetButton = await waitFor(() => {
    // The dropdown items are <button role="option"> elements
    const options = document.querySelectorAll('button[role="option"]');
    for (const btn of options) {
      // The ticker lives inside a <span> inside <p>, sibling to the exchange <span>
      // Structure: <p><span>AMZN</span><span>NASDAQ</span></p>
      const spans = btn.querySelectorAll(
        'p[class*="TickerListItemInfoExchange"] span, ' +    // preferred
        'p span'                                             // fallback
      );
      for (const span of spans) {
        if (span.textContent.trim().toUpperCase() === symbol.toUpperCase()) {
          return btn; // found it
        }
      }
    }
    return null;
  }, 8000);

  console.log(`[searchStock] Found dropdown option for "\${symbol.toUpperCase()}". Clicking…`);

  // ── Step 4: Click the matching option ─────────────────────────────────────

  targetButton.click();
  console.log(`[searchStock] ✅ Done — selected \${symbol.toUpperCase()}.`);

  // ── Step 5: Anchor horizontal overflow to the right ─────────────────────
  // Webull's stocks page has a min-width of ~1000px. When the WebView panel is
  // narrower than that, the leftmost columns (watchlist, chart) take up all the
  // visible space and the right-side trading panel is hidden off-screen. Force
  // the page to be horizontally scrollable and pin the scroll position to the
  // right so the trading panel is the default visible region.

  const anchorStyle = document.createElement('style');
  anchorStyle.id = 'halo-anchor-right';
  anchorStyle.textContent = \`
    html, body { overflow-x: auto !important; }
    main, [class*="Portal__PortalContent"], [class*="Portal__PortalBody"] {
      overflow-x: visible !important;
    }
  \`;
  document.head.appendChild(anchorStyle);

  const anchorRight = () => {
    const el = document.scrollingElement || document.documentElement;
    if (el && el.scrollWidth > el.clientWidth) {
      el.scrollLeft = el.scrollWidth;
    }
  };

  anchorRight();
  window.addEventListener('resize', anchorRight);
  window.addEventListener('load', anchorRight);
  setInterval(anchorRight, 250);
  new MutationObserver(anchorRight).observe(document.body, {
    childList: true, subtree: true,
  });

  console.log('[Halo] Anchored Webull overflow to the right for ' + symbol);

  window.flutter_inappwebview.callHandler('HaloAuthReady', 'ready');
})();
""";
}

List<UserScript> getBrowserStartupScripts(String stock, SettingsHandler settings) {
  print("onboarding flow : ${settings.buyingPlatform!.id}");
  if(settings.buyingPlatform == null) return [];

  if(settings.buyingPlatform!.id == "Webull") return [
    UserScript(
      source:  openWebullEditor(stock),
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
    )
  ];

  return [];
}