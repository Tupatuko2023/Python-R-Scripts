2.  **DATA_ROOT:** Raakadata luetaan VAIN ympäristömuuttujan `DATA_ROOT` osoittamasta polusta (ulkoinen tallennus).
    **AGENTTIOHJE: DATA_ROOT – ainoa sallittu toimintatapa**

    Ennen kuin ajat mitään tässä repossa

    Aina, ilman poikkeuksia, tee tämä ensin:

    `bash Quantify-FOF-Utilization-Costs/scripts/bootstrap_env.sh`

    Tulkinta bootstrapin tuloksesta

    Jos bootstrap onnistuu (exit 0 / OK):

    DATA_ROOT on asetettu oikein

    jatka välittömästi QC-, smoke- tai R-ajoihin

    älä tulosta DATA_ROOT-arvoa

    Jos bootstrap epäonnistuu (exit ≠ 0 / FAIL):

    älä kysy DATA_ROOT-polkuja chatissa

    älä yritä arvata tai etsiä dataa

    ilmoita tehtävä BLOCKED (environment missing)

    ohjaa käyttäjää asettamaan DATA_ROOT paikallisesti tiedostoon:

    `Quantify-FOF-Utilization-Costs/config/.env`

    rivi:

    `DATA_ROOT=<OMA_PAIKALLINEN_ABSOLUUTTINEN_POLKU>`

    Tämän jälkeen bootstrap ajetaan uudelleen.

    Sallitut ja kielletyt toimet

    ✅ Sallittua

    Ajaa DATA_ROOTiin perustuvat ajot vain bootstrapin jälkeen

    Tarkistaa DATA_ROOT vain OK/FAIL-muodossa

    Ohjata stdout/stderr lokitiedostoon

    Merkitä tehtävä blockediksi ympäristösyistä

    ❌ Kiellettyä

    Tulostaa DATA_ROOT-arvoa (stdout, stderr, logit, chat)

    Echoa, printata tai debugata polkua

    Skannata tiedostojärjestelmää DATA_ROOTin löytämiseksi

    Kysyä käyttäjältä DATA_ROOT-polkuja chatissa

    Ajaa skriptejä, jos bootstrap epäonnistuu

    (Valinnainen) direnv

    Jos direnv on käytössä:

    `cd Quantify-FOF-Utilization-Costs`

    `direnv allow`

    Tämä helpottaa uusia sessioita, mutta ei korvaa bootstrapia.
    Bootstrap on aina sallittu ja suositeltu.

    Yleinen periaate (muista tämä)

    Oikeus ajaa ≠ kyky ajaa.
    Jos DATA_ROOT ei ole saatavilla ajoympäristössä, tehtävä pysähtyy oikein fail-closed-tilaan.
