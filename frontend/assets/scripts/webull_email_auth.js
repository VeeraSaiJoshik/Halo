(async () => {
  const waitFor = (findFn, timeout = 8000) => new Promise((resolve) => {
    const start = Date.now();
    const check = () => {
      const el = findFn();
      if (el) return resolve(el);
      if (Date.now() - start > timeout) return resolve(null);
      requestAnimationFrame(check);
    };
    check();
  });
  const span = await waitFor(() =>
    [...document.querySelectorAll('span')].find(s => s.textContent.trim() === 'Email Login')
  );
  if (span) span.click();
  HaloAuthReady.postMessage('ready');
})();
