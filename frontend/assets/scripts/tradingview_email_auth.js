(async () => {
  const waitFor = (findFn, timeout = 5000) => new Promise((resolve) => {
    const start = Date.now();
    const check = () => {
      const el = findFn();
      if (el) return resolve(el);
      if (Date.now() - start > timeout) return resolve(null);
      requestAnimationFrame(check);
    };
    check();
  });

  const clickEl = (el) => {
    const target = el.closest('button, a, [role="button"], [onclick]') || el;
    target.click();
  };

  const menuBtn = await waitFor(() =>
    document.querySelector('[aria-label="Open user menu"]')
    || [...document.querySelectorAll('button')].find(b => b.textContent.trim() === 'Open user menu')
  );
  if (!menuBtn) { window.flutter_inappwebview.callHandler('HaloAuthReady', 'ready'); return; }
  clickEl(menuBtn);

  const cls = 'label-jFqVJoPk.label-mDJVFqQ3.label-YQGjel_5';
  const span = await waitFor(() => document.querySelector(`span.${cls}`));
  if (!span) { window.flutter_inappwebview.callHandler('HaloAuthReady', 'ready'); return; }
  clickEl(span);

  const emailBtn = await waitFor(() =>
    [...document.querySelectorAll('button, a, [role="button"], span')]
      .find(b => b.textContent.trim() === 'Email')
  );
  if (!emailBtn) { window.flutter_inappwebview.callHandler('HaloAuthReady', 'ready'); return; }
  clickEl(emailBtn);

  window.flutter_inappwebview.callHandler('HaloAuthReady', 'ready');
})();
