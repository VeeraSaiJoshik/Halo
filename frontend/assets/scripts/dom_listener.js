(function() {
  const meta = document.querySelector('meta[name="viewport"]');
  if (meta) meta.content = 'width=device-width, initial-scale=1.0, user-scalable=yes';

  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      window.flutter_inappwebview.callHandler('onDOMChange', {
        type: mutation.type,
        target: mutation.target.id || mutation.target.className
      });
    });
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    characterData: true
  });
})();
