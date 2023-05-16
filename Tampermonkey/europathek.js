// ==UserScript==
// @name         Europathek DL Helper
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  try to take over the world!
// @author       You
// @match        https://www.europathek.de/de/*
// @grant        GM_download
// ==/UserScript==

(async function () {
  'use strict';

  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  let iframe = document.getElementsByTagName('iframe')[0];

  while (iframe == undefined) {
    iframe = document.getElementsByTagName('iframe')[0];
    await sleep(500)
  }

  if (iframe) {
    const baseUrl = iframe.src;
    const imageUrl = baseUrl.replace(/index.html$/, "preview/big/");
    const xmlUrl = baseUrl.replace(/index.html$/, "xml/book.xml");
    const xmlResponse = await fetch(xmlUrl);
    const xml = await xmlResponse.text();
    const xmlDoc = new DOMParser().parseFromString(xml, "text/xml");
    const pagecounter = parseInt(xmlDoc.getElementsByTagName("pages")[0].getAttribute("pagecounter"));
    const bookId = xmlDoc.getElementsByTagName("book")[0].getAttribute("id");

    if (pagecounter && bookId) {
      for (let index = 1; index <= pagecounter; index++) {
        const arg = {
          url: `${imageUrl}${index}.jpg`,
          name: `${bookId}/${index}.jpg`,
        };
        const time = Math.random() * 100 + 1500;

        console.log({ arg, time });

        GM_download(arg);
        await sleep(time);
      }
    }
  }
})();
