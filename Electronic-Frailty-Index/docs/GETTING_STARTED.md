# Getting Started

Tämä ohje käynnistää projektin 10 minuutissa. Tässä ei ole oikeaa dataa. Demot käyttävät synteettistä CSV:tä.

## Esivaatimukset
- Windows 10 tai 11
- VS Code
- Conda tai Miniconda
- R 4.x
- Quarto 1.8.x
- Node LTS jos haluat markdownlintin
- TinyTeX PDF-rendaukseen [TODO: linkki ohjeeseen]

## Kansiot pikavilkaisulla
- docs: dokumentit ja tämä ohje
- report: Quarto raportit
- env: ympäristökuvaukset
- notebooks: analyysinotebookit
- docs/SYNTHETIC_DEMO: synteettinen CSV ja demot

## Python: ympäristö ja demo
```powershell
conda env create -f env\environment.yml
conda activate efi
python docs\SYNTHETIC_DEMO\demo_py.py
