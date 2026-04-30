(async () => {                                                  
    const waitFor = (findFn, timeout = 5000) => new Promise((resolve) => {
      const start = Date.now();                                                                                                                     
      const poll = () => {
        const el = findFn();                                                                                                                        
        if (el) return resolve(el);                               
        if (Date.now() - start > timeout) return resolve(null);                                                                                     
        setTimeout(poll, 100);
      };                                                                                                                                            
      poll();                                                     
    });

    const done = () => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('HaloAuthReady', 'ready');                                                                          
      }
    };                                                                                                                                              
                                                                  
    // Step 1: Open menu
    const menuBtn = await waitFor(() =>
      document.querySelector('[aria-label="Open user menu"]')                                                                                       
    );
    if (!menuBtn) { console.log('❌ menuBtn not found'); done(); return; }                                                                          
    console.log('✅ menuBtn found'); menuBtn.click();             
                                                                                                                                                    
    // Step 2: Click Sign in (stable data-name selector)
    await new Promise(r => setTimeout(r, 500));                                                                                                     
    const signInBtn = await waitFor(() =>                                                                                                           
      document.querySelector('[data-name="header-user-menu-sign-in"]')
    );                                                                                                                                              
    if (!signInBtn) { console.log('❌ signInBtn not found'); done(); return; }
    console.log('✅ signInBtn found'); signInBtn.click();                                                                                           
   
    // Step 3: Click Google button                                                                                                                  
    const googleBtn = await waitFor(() =>                         
      document.querySelector('div.nsm7Bb-HzV7m-LgbsSe-MJoBVe')                                                                                      
    );
    if (!googleBtn) { console.log('❌ googleBtn not found'); done(); return; }                                                                      
    console.log('✅ googleBtn found'); googleBtn.click();         
                                                                                                                                                    
    done();
  })();      