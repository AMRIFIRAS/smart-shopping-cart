# Product image sources

Downloaded and visually checked on 14 September 2026. Real package photographs
are stored locally under `assets/products/`; none are hotlinked at runtime.
Each image is a 768 × 768 JPEG on white. The five files total about 355 KB.

| ID | Selected package | Source page | Local file |
| --- | --- | --- | --- |
| P001 | Almarai Fresh Full Fat Milk, 1 L PET bottle | [Almarai official](https://www.almarai.com/en/brands/almarai/liquid-dairy/fresh-milk/fresh-milk-full-fat) | `almarai.jpg` |
| P002 | Nadec 100% Orange Juice, 1.3 L bottle | [Nadec official](https://www.nadec.com/en/products/281) | `nadec.jpg` |
| P003 | Berain drinking water, individual 600 ml bottle | [Spinneys Saudi Arabia](https://www.spinneys.com/en-sa/catalogue/berain-water-600ml_81213/) | `berain.jpg` |
| P004 | Twix Original, two bars, 50 g | [LuLu Saudi Arabia](https://gcc.luluhypermarket.com/en-sa/twix-original-chocolate-bar-2-bars-50-g/p/903138-ea/?convtobuom=1) | `twix.jpg` |
| P005 | Doritos Nacho Cheese tortilla chips, 48 g | [LuLu Saudi Arabia](https://gcc.luluhypermarket.com/en-sa/doritos-nacho-cheese-tortilla-chips-48-g/p/1399102/) | `doritos.jpg` |

Original image endpoints:

- Almarai: `https://almmedia.almarai.com/Gallery/21130-MILK-FF-1L-PET-%281X20%29-EN510202575544AM.PNG`
- Nadec: `https://www.nadec.com/sites/default/files/2025-02/Orange1.3L-Eya.png`
- Berain: `https://prod-spinneys-cdn-new.azureedge.net/media/cache/59/eb/59ebe9ef86e9cf86b2d80daa58c14c83.jpg`
- Twix: `https://bf1af2.akinoncloudcdn.com/products/2025/12/19/97796/30592cf4-2403-42ca-ad52-f99f3683c7b6_size3840_cropCenter.jpg`
- Doritos: `https://bf1af2.akinoncloudcdn.com/products/2025/02/17/72640/8cd0ced3-0a42-41c4-b42d-13ed005b1863_size3840_cropCenter.jpg`

Nadec uses the documented 1.3 L package, replacing the earlier illustrative 1 L
size. Berain's retailer photograph shows the older purple-cap design. Packaging
can change. SmartCart QR labels link to product pages; they are not manufacturer IDs.

Prices, nutrition, and descriptions remain editable demo data in
`lib/data/demo_products.dart`. They are not certified or transcribed from these
photographs. Update them after inspecting the exact demonstration packages.
Brand marks and photographs belong to their owners; attribution does not imply
an open-source image license or endorsement.

Run `dart run tool/optimize_product_images.dart` after supplying originals in
`.dart_tool/raw-images/` to reproduce optimization. Font licenses are bundled
under `assets/fonts/`. The SmartCart mark is original code artwork in
`lib/widgets/brand_mark.dart`, with icons from `tool/generate_brand_icons.dart`.
