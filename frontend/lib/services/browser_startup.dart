import 'package:flutter_inappwebview/flutter_inappwebview.dart';

String openWebullEditor(String stock) {
  return """

(async () => {
const stock = "${stock}";
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

  console.log(`[searchStock] Looking for search bar…`);

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

  let searchInput = null;
  for (const sel of SEARCH_SELECTORS) {
    searchInput = document.querySelector(sel);
    if (searchInput) {
      console.log(`[searchStock] Found input with selector: \${sel}`);
      break;
    }
  }

  if (!searchInput) {
    throw new Error(
      "Could not find the Symbol/Name search input. " +
      "Inspect the input element and add its selector to SEARCH_SELECTORS."
    );
  }

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
  window.flutter_inappwebview.callHandler('HaloAuthReady', 'ready');
})();

async function searchStock(symbol) {
  // ── Helpers ────────────────────────────────────────────────────────────────

  
}

// ── Run ─────────────────────────────────────────────────────────────────────
// Change the symbol here or call searchStock() from your own code.
searchStock("${stock}");
""";
}

List<UserScript> getBrowserStartupScripts(String stock) {
  return [
    UserScript(
      source: openWebullEditor(stock),
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    )
  ];
}