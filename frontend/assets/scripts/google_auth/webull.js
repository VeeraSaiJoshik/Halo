(async () => {               
  console.log("stated this");
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

    const div = await waitFor(() =>
      document.querySelector('div.csr142.csr139')
    );                       
    
    console.log("found the div")
    console.log(div.innerText)
    if (div) div.click();
    console.log("Successfully injected");                                                                                                           
  })();